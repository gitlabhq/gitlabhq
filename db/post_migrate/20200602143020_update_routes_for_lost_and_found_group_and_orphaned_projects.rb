# frozen_string_literal: true

# This migration adds or updates the routes for all the entities affected by
#  post-migration '20200511083541_cleanup_projects_with_missing_namespace'
# - A route is added for the 'lost-and-found' group
# - A route is added for the Ghost user (if not already defined)
# - The routes for all the orphaned projects that were moved under the 'lost-and-found'
#   group are updated to reflect the new path
class UpdateRoutesForLostAndFoundGroupAndOrphanedProjects < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class User < ActiveRecord::Base
    self.table_name = 'users'

    LOST_AND_FOUND_GROUP = 'lost-and-found'
    USER_TYPE_GHOST = 5
    ACCESS_LEVEL_OWNER = 50

    has_one :namespace, -> { where(type: nil) },
            foreign_key: :owner_id, inverse_of: :owner, autosave: true,
            class_name: 'UpdateRoutesForLostAndFoundGroupAndOrphanedProjects::Namespace'

    def lost_and_found_group
      # Find the 'lost-and-found' group
      # There should only be one Group owned by the Ghost user starting with 'lost-and-found'
      Group
        .joins('INNER JOIN members ON namespaces.id = members.source_id')
        .where(namespaces: { type: 'Group' })
        .where(members: { type: 'GroupMember' })
        .where(members: { source_type: 'Namespace' })
        .where(members: { user_id: self.id })
        .where(members: { access_level: ACCESS_LEVEL_OWNER })
        .find_by(Group.arel_table[:name].matches("#{LOST_AND_FOUND_GROUP}%"))
    end

    class << self
      # Return the ghost user
      def ghost
        User.find_by(user_type: USER_TYPE_GHOST)
      end
    end
  end

  # Temporary Concern to not repeat the same methods twice
  module HasPath
    extend ActiveSupport::Concern

    def full_path
      if parent && path
        parent.full_path + '/' + path
      else
        path
      end
    end

    def full_name
      if parent && name
        parent.full_name + ' / ' + name
      else
        name
      end
    end
  end

  class Namespace < ActiveRecord::Base
    include HasPath

    self.table_name = 'namespaces'

    belongs_to :owner, class_name: 'UpdateRoutesForLostAndFoundGroupAndOrphanedProjects::User'
    belongs_to :parent, class_name: "UpdateRoutesForLostAndFoundGroupAndOrphanedProjects::Namespace"
    has_many :children, foreign_key: :parent_id,
             class_name: "UpdateRoutesForLostAndFoundGroupAndOrphanedProjects::Namespace"
    has_many :projects, class_name: "UpdateRoutesForLostAndFoundGroupAndOrphanedProjects::Project"

    def ensure_route!
      unless Route.for_source('Namespace', self.id)
        Route.create!(
          source_id: self.id,
          source_type: 'Namespace',
          path: self.full_path,
          name: self.full_name
        )
      end
    end

    def generate_unique_path
      # Generate a unique path if there is no route for the namespace
      # (an existing route guarantees that the path is already unique)
      unless Route.for_source('Namespace', self.id)
        self.path = Uniquify.new.string(self.path) do |str|
          Route.where(path: str).exists?
        end
      end
    end
  end

  class Group < Namespace
    # Disable STI to allow us to manually set "type = 'Group'"
    # Otherwise rails forces "type = CleanupProjectsWithMissingNamespace::Group"
    self.inheritance_column = :_type_disabled
  end

  class Route < ActiveRecord::Base
    self.table_name = 'routes'

    def self.for_source(source_type, source_id)
      Route.find_by(source_type: source_type, source_id: source_id)
    end
  end

  class Project < ActiveRecord::Base
    include HasPath

    self.table_name = 'projects'

    belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'namespace_id',
      class_name: "UpdateRoutesForLostAndFoundGroupAndOrphanedProjects::Group"
    belongs_to :namespace,
      class_name: "UpdateRoutesForLostAndFoundGroupAndOrphanedProjects::Namespace"

    alias_method :parent, :namespace
    alias_attribute :parent_id, :namespace_id

    def ensure_route!
      Route.find_or_initialize_by(source_type: 'Project', source_id: self.id).tap do |record|
        record.path = self.full_path
        record.name = self.full_name
        record.save!
      end
    end
  end

  def up
    # Reset the column information of all the models that update the database
    # to ensure the Active Record's knowledge of the table structure is current
    Namespace.reset_column_information
    Route.reset_column_information
    User.reset_column_information

    # Find the ghost user, its namespace and the "lost and found" group
    ghost_user = User.ghost
    return unless ghost_user # No reason to continue if there is no Ghost user

    ghost_namespace = ghost_user.namespace
    lost_and_found_group = ghost_user.lost_and_found_group

    # No reason to continue if there is no 'lost-and-found' group
    # 1. No orphaned projects were found in this instance, or
    # 2. The 'lost-and-found' group and the orphaned projects have been already deleted
    return unless lost_and_found_group

    # Update the 'lost-and-found' group description to be more self-explanatory
    lost_and_found_group.generate_unique_path
    lost_and_found_group.description =
      'Group for storing projects that were not properly deleted. '\
      'It should be considered as a system level Group with non-working '\
      'projects inside it. The contents may be deleted with a future update. '\
      'More info: gitlab.com/gitlab-org/gitlab/-/issues/198603'
    lost_and_found_group.save!

    # make sure that the ghost namespace has a unique path
    ghost_namespace.generate_unique_path

    if ghost_namespace.path_changed?
      ghost_namespace.save!
      # If the path changed, also update the Ghost User's username to match the new path.
      ghost_user.update!(username: ghost_namespace.path)
    end

    # Update the routes for the Ghost user, the "lost and found" group
    # and all the orphaned projects
    ghost_namespace.ensure_route!
    lost_and_found_group.ensure_route!

    # The following does a fast index scan by namespace_id
    # No reason to process in batches:
    # - 66 projects in GitLab.com, less than 1ms execution time to fetch them
    #   with a constant update time for each
    lost_and_found_group.projects.each do |project|
      project.ensure_route!
    end
  end

  def down
    # no-op
  end
end
