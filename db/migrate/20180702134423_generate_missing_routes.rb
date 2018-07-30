# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# This migration generates missing routes for any projects and namespaces that
# don't already have a route.
#
# On GitLab.com this would insert 611 project routes, and 0 namespace routes.
# The exact number could vary per instance, so we take care of both just in
# case.
class GenerateMissingRoutes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  class Route < ActiveRecord::Base
    self.table_name = 'routes'
  end

  module Routable
    def build_full_path
      if parent && path
        parent.build_full_path + '/' + path
      else
        path
      end
    end

    def build_full_name
      if parent && name
        parent.human_name + ' / ' + name
      else
        name
      end
    end

    def human_name
      build_full_name
    end

    def attributes_for_insert
      time = Time.zone.now

      {
        # We can't use "self.class.name" here as that would include the
        # migration namespace.
        source_type: source_type_for_route,
        source_id: id,
        created_at: time,
        updated_at: time,
        name: build_full_name,

        # The route path might already be taken. Instead of trying to generate a
        # new unique name on every conflict, we just append the row ID to the
        # route path.
        path: "#{build_full_path}-#{id}"
      }
    end
  end

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include EachBatch
    include GenerateMissingRoutes::Routable

    belongs_to :namespace, class_name: 'GenerateMissingRoutes::Namespace'

    has_one :route,
      as: :source,
      inverse_of: :source,
      class_name: 'GenerateMissingRoutes::Route'

    alias_method :parent, :namespace
    alias_attribute :parent_id, :namespace_id

    def self.without_routes
      where(
        'NOT EXISTS (
          SELECT 1
          FROM routes
          WHERE source_type = ?
          AND source_id = projects.id
        )',
        'Project'
      )
    end

    def source_type_for_route
      'Project'
    end
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'

    include EachBatch
    include GenerateMissingRoutes::Routable

    belongs_to :parent, class_name: 'GenerateMissingRoutes::Namespace'
    belongs_to :owner, class_name: 'GenerateMissingRoutes::User'

    has_one :route,
      as: :source,
      inverse_of: :source,
      class_name: 'GenerateMissingRoutes::Route'

    def self.without_routes
      where(
        'NOT EXISTS (
          SELECT 1
          FROM routes
          WHERE source_type = ?
          AND source_id = namespaces.id
        )',
        'Namespace'
      )
    end

    def source_type_for_route
      'Namespace'
    end
  end

  def up
    [Namespace, Project].each do |model|
      model.without_routes.each_batch(of: 100) do |batch|
        rows = batch.map(&:attributes_for_insert)

        Gitlab::Database.bulk_insert(:routes, rows)
      end
    end
  end

  def down
    # Removing routes we previously generated makes no sense.
  end
end
