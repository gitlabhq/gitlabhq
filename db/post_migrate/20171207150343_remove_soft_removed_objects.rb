# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveSoftRemovedObjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  module SoftRemoved
    extend ActiveSupport::Concern

    included do
      scope :soft_removed, -> { where('deleted_at IS NOT NULL') }
    end
  end

  class User < ActiveRecord::Base
    self.table_name = 'users'

    include EachBatch
  end

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'

    include EachBatch
    include SoftRemoved
  end

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'

    include EachBatch
    include SoftRemoved
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'

    include EachBatch
    include SoftRemoved

    scope :soft_removed_personal, -> { soft_removed.where(type: nil) }
    scope :soft_removed_group, -> { soft_removed.where(type: 'Group') }
  end

  class Route < ActiveRecord::Base
    self.table_name = 'routes'

    include EachBatch
    include SoftRemoved
  end

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include EachBatch
    include SoftRemoved
  end

  class CiPipelineSchedule < ActiveRecord::Base
    self.table_name = 'ci_pipeline_schedules'

    include EachBatch
    include SoftRemoved
  end

  class CiTrigger < ActiveRecord::Base
    self.table_name = 'ci_triggers'

    include EachBatch
    include SoftRemoved
  end

  MODELS = [Issue, MergeRequest, CiPipelineSchedule, CiTrigger].freeze

  def up
    disable_statement_timeout

    remove_personal_routes
    remove_personal_namespaces
    remove_group_namespaces
    remove_simple_soft_removed_rows
  end

  def down
    # The data removed by this migration can't be restored in an automated way.
  end

  def remove_simple_soft_removed_rows
    create_temporary_indexes

    MODELS.each do |model|
      say_with_time("Removing soft removed rows from #{model.table_name}") do
        model.soft_removed.each_batch do |batch, index|
          batch.delete_all
        end
      end
    end
  ensure
    remove_temporary_indexes
  end

  def create_temporary_indexes
    MODELS.each do |model|
      index_name = temporary_index_name_for(model)

      # Without this index the removal process can take a very long time. For
      # example, getting the next ID of a batch for the `issues` table in
      # staging would take between 15 and 20 seconds.
      next if temporary_index_exists?(model)

      say_with_time("Creating temporary index #{index_name}") do
        add_concurrent_index(
          model.table_name,
          [:deleted_at, :id],
          name: index_name,
          where: 'deleted_at IS NOT NULL'
        )
      end
    end
  end

  def remove_temporary_indexes
    MODELS.each do |model|
      index_name = temporary_index_name_for(model)

      next unless temporary_index_exists?(model)

      say_with_time("Removing temporary index #{index_name}") do
        remove_concurrent_index_by_name(model.table_name, index_name)
      end
    end
  end

  def temporary_index_name_for(model)
    "index_on_#{model.table_name}_tmp"
  end

  def temporary_index_exists?(model)
    index_name = temporary_index_name_for(model)

    index_exists?(model.table_name, [:deleted_at, :id], name: index_name)
  end

  def remove_personal_namespaces
    # Some personal namespaces are left behind in case of GitLab.com. In these
    # cases the associated data such as the projects and users has already been
    # removed.
    Namespace.soft_removed_personal.each_batch do |batch|
      batch.delete_all
    end
  end

  def remove_group_namespaces
    admin_id = id_for_admin_user

    unless admin_id
      say 'Not scheduling soft removed groups for removal as no admin user ' \
        'could be found. You will need to remove any such groups manually.'

      return
    end

    # Left over groups can't be easily removed because we may also need to
    # remove memberships, repositories, and other associated data. As a result
    # we'll just schedule a Sidekiq job to remove these.
    #
    # As of January 5th, 2018 there are 36 groups that will be removed using
    # this code.
    Namespace.select(:id).soft_removed_group.each_batch(of: 10) do |batch, index|
      batch.each do |ns|
        schedule_group_removal(index * 5.minutes, ns.id, admin_id)
      end
    end
  end

  def schedule_group_removal(delay, group_id, user_id)
    if migrate_inline?
      GroupDestroyWorker.new.perform(group_id, user_id)
    else
      GroupDestroyWorker.perform_in(delay, group_id, user_id)
    end
  end

  def remove_personal_routes
    namespaces = Namespace.select(1)
      .soft_removed
      .where('namespaces.type IS NULL')
      .where('routes.source_type = ?', 'Namespace')
      .where('routes.source_id = namespaces.id')

    Route.where('EXISTS (?)', namespaces).each_batch do |batch|
      batch.delete_all
    end
  end

  def id_for_admin_user
    User.where(admin: true).limit(1).pluck(:id).first
  end

  def migrate_inline?
    Rails.env.test? || Rails.env.development?
  end
end
