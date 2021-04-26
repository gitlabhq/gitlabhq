# frozen_string_literal: true

# rubocop:disable Migration/PreventStrings

# This migration cleans up Projects that were orphaned when their namespace was deleted
# Instead of deleting them, we:
# - Find (or create) the Ghost User
# - Create (if not already exists) a `lost-and-found` group owned by the Ghost User
# - Find orphaned projects --> namespace_id can not be found in namespaces
# - Move the orphaned projects to the `lost-and-found` group
#   (while making them private and setting `archived=true`)
#
# On GitLab.com (2020-05-11) this migration will update 66 orphaned projects
class CleanupProjectsWithMissingNamespace < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  VISIBILITY_PRIVATE = 0
  ACCESS_LEVEL_OWNER = 50

  # The batch size of projects to check in each iteration
  # We expect the selectivity for orphaned projects to be very low:
  #  (66 orphaned projects out of a total 13.6M)
  # so 10K should be a safe choice
  BATCH_SIZE = 10000

  disable_ddl_transaction!

  class UserDetail < ActiveRecord::Base
    self.table_name = 'user_details'

    belongs_to :user, class_name: 'CleanupProjectsWithMissingNamespace::User'
  end

  class User < ActiveRecord::Base
    self.table_name = 'users'

    LOST_AND_FOUND_GROUP = 'lost-and-found'
    USER_TYPE_GHOST = 5
    DEFAULT_PROJECTS_LIMIT = 100000

    default_value_for :admin, false
    default_value_for :can_create_group, true # we need this to create the group
    default_value_for :can_create_team, false
    default_value_for :project_view, :files
    default_value_for :notified_of_own_activity, false
    default_value_for :preferred_language, I18n.default_locale

    has_one :user_detail, class_name: 'CleanupProjectsWithMissingNamespace::UserDetail'
    has_one :namespace, -> { where(type: nil) },
            foreign_key: :owner_id, inverse_of: :owner, autosave: true,
            class_name: 'CleanupProjectsWithMissingNamespace::Namespace'

    before_save :ensure_namespace_correct
    before_save :ensure_bio_is_assigned_to_user_details, if: :bio_changed?

    enum project_view: { readme: 0, activity: 1, files: 2 }

    def ensure_namespace_correct
      if namespace
        namespace.path = username if username_changed?
        namespace.name = name if name_changed?
      else
        build_namespace(path: username, name: name)
      end
    end

    def ensure_bio_is_assigned_to_user_details
      user_detail.bio = bio.to_s[0...255]
    end

    def user_detail
      super.presence || build_user_detail
    end

    # Return (or create if necessary) the `lost-and-found` group
    def lost_and_found_group
      existing_lost_and_found_group || Group.create_unique_group(self, LOST_AND_FOUND_GROUP)
    end

    def existing_lost_and_found_group
      # There should only be one Group for User Ghost starting with LOST_AND_FOUND_GROUP
      Group
        .joins('INNER JOIN members ON namespaces.id = members.source_id')
        .where(namespaces: { type: 'Group' })
        .where(members: { type: 'GroupMember' })
        .where(members: { source_type: 'Namespace' })
        .where(members: { user_id: self.id })
        .where(members: { requested_at: nil })
        .where(members: { access_level: ACCESS_LEVEL_OWNER })
        .find_by(Group.arel_table[:name].matches("#{LOST_AND_FOUND_GROUP}%"))
    end

    class << self
      # Return (or create if necessary) the ghost user
      def ghost
        email = 'ghost%s@example.com'

        unique_internal(where(user_type: USER_TYPE_GHOST), 'ghost', email) do |u|
          u.bio = _('This is a "Ghost User", created to hold all issues authored by users that have since been deleted. This user cannot be removed.')
          u.name = 'Ghost User'
        end
      end

      def unique_internal(scope, username, email_pattern, &block)
        scope.first || create_unique_internal(scope, username, email_pattern, &block)
      end

      def create_unique_internal(scope, username, email_pattern, &creation_block)
        # Since we only want a single one of these in an instance, we use an
        # exclusive lease to ensure that this block is never run concurrently.
        lease_key = "user:unique_internal:#{username}"
        lease = Gitlab::ExclusiveLease.new(lease_key, timeout: 1.minute.to_i)

        until uuid = lease.try_obtain
          # Keep trying until we obtain the lease. To prevent hammering Redis too
          # much we'll wait for a bit between retries.
          sleep(1)
        end

        # Recheck if the user is already present. One might have been
        # added between the time we last checked (first line of this method)
        # and the time we acquired the lock.
        existing_user = uncached { scope.first }
        return existing_user if existing_user.present?

        uniquify = Uniquify.new

        username = uniquify.string(username) { |s| User.find_by_username(s) }

        email = uniquify.string(-> (n) { Kernel.sprintf(email_pattern, n) }) do |s|
          User.find_by_email(s)
        end

        User.create!(
          username: username,
          email: email,
          user_type: USER_TYPE_GHOST,
          projects_limit: DEFAULT_PROJECTS_LIMIT,
          state: :active,
          &creation_block
        )
      ensure
        Gitlab::ExclusiveLease.cancel(lease_key, uuid)
      end
    end
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'

    belongs_to :owner, class_name: 'CleanupProjectsWithMissingNamespace::User'
  end

  class Group < Namespace
    # Disable STI to allow us to manually set "type = 'Group'"
    # Otherwise rails forces "type = CleanupProjectsWithMissingNamespace::Group"
    self.inheritance_column = :_type_disabled

    def self.create_unique_group(user, group_name)
      # 'lost-and-found' may be already defined, find a unique one
      group_name = Uniquify.new.string(group_name) do |str|
        Group.where(parent_id: nil, name: str).exists?
      end

      group = Group.create!(
        name: group_name,
        path: group_name,
        type: 'Group',
        description: 'Group to store orphaned projects',
        visibility_level: VISIBILITY_PRIVATE
      )

      # No need to create a route for the lost-and-found group

      GroupMember.add_user(group, user, ACCESS_LEVEL_OWNER)

      group
    end
  end

  class Member < ActiveRecord::Base
    self.table_name = 'members'
  end

  class GroupMember < Member
    NOTIFICATION_SETTING_GLOBAL = 3

    # Disable STI to allow us to manually set "type = 'GroupMember'"
    # Otherwise rails forces "type = CleanupProjectsWithMissingNamespace::GroupMember"
    self.inheritance_column = :_type_disabled

    def self.add_user(source, user, access_level)
      GroupMember.create!(
        type: 'GroupMember',
        source_id: source.id,
        user_id: user.id,
        source_type: 'Namespace',
        access_level: access_level,
        notification_level: NOTIFICATION_SETTING_GLOBAL
      )
    end
  end

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include ::EachBatch

    def self.without_namespace
      where(
        'NOT EXISTS (
          SELECT 1
          FROM namespaces
          WHERE projects.namespace_id = namespaces.id
        )'
      )
    end
  end

  def up
    # Reset the column information of all the models that update the database
    # to ensure the Active Record's knowledge of the table structure is current
    User.reset_column_information
    Namespace.reset_column_information
    Member.reset_column_information
    Project.reset_column_information

    # Find or Create the ghost user
    ghost_user = User.ghost

    # Find or Create the `lost-and-found`
    lost_and_found = ghost_user.lost_and_found_group

    # With BATCH_SIZE=10K and projects.count=13.6M
    # ~1360 iterations will be run:
    # - each requires on average ~160ms for relation.without_namespace
    # - worst case scenario is that 66 of those batches will trigger an update (~200ms each)
    #   In general, we expect less than 5% (=66/13.6M x 10K) to trigger an update
    # Expected total run time: ~235 seconds (== 220 seconds + 14 seconds)
    Project.each_batch(of: BATCH_SIZE) do |relation|
      relation.without_namespace.update_all <<~SQL
        namespace_id = #{lost_and_found.id},
        archived = TRUE,
        visibility_level = #{VISIBILITY_PRIVATE},

        -- Names are expected to be unique inside their namespace
        --  (uniqueness validation on namespace_id, name)
        -- Attach the id to the name and path to make sure that they are unique
        name = name || '_' || id::text,
        path = path || '_' || id::text
      SQL
    end
  end

  def down
    # no-op: the original state for those projects was inconsistent
    # Also, the original namespace_id for each project is lost during the update
  end
end
# rubocop:enable Migration/PreventStrings
