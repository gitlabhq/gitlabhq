# frozen_string_literal: true

module Members
  # This class serves as more of an app-wide way we add/create members
  # All roads to add members should take this path.
  class CreatorService
    class << self
      def parsed_access_level(access_level)
        access_levels.fetch(access_level) { access_level.to_i }
      end

      def access_levels
        Gitlab::Access.sym_options_with_owner
      end
    end

    def initialize(source, user, access_level, **args)
      @source = source
      @user = user
      @access_level = self.class.parsed_access_level(access_level)
      @args = args
    end

    def execute
      find_or_build_member
      commit_member
      create_member_task

      member
    end

    private

    delegate :new_record?, to: :member
    attr_reader :source, :user, :access_level, :member, :args

    def assign_member_attributes
      member.attributes = member_attributes
    end

    def commit_member
      if can_commit_member?
        assign_member_attributes
        commit_changes
      else
        add_commit_error
      end
    end

    def can_commit_member?
      # There is no current user for bulk actions, in which case anything is allowed
      return true if skip_authorization?

      if new_record?
        can_create_new_member?
      else
        can_update_existing_member?
      end
    end

    def can_create_new_member?
      raise NotImplementedError
    end

    def can_update_existing_member?
      raise NotImplementedError
    end

    # Populates the attributes of a member.
    #
    # This logic resides in a separate method so that EE can extend this logic,
    # without having to patch the `add_user` method directly.
    def member_attributes
      {
        created_by: member.created_by || current_user,
        access_level: access_level,
        expires_at: args[:expires_at]
      }
    end

    def commit_changes
      if member.request?
        approve_request
      else
        member.save
      end
    end

    def create_member_task
      return unless member.persisted?
      return if member_task_attributes.value?(nil)
      return if member.member_task.present?

      member.create_member_task(member_task_attributes)
    end

    def member_task_attributes
      {
        tasks_to_be_done: args[:tasks_to_be_done],
        project_id: args[:tasks_project_id]
      }
    end

    def approve_request
      ::Members::ApproveAccessRequestService.new(current_user,
                                                 access_level: access_level)
                                            .execute(
                                              member,
                                              skip_authorization: ldap,
                                              skip_log_audit_event: ldap
                                            )
    end

    def current_user
      args[:current_user]
    end

    def skip_authorization?
      !current_user
    end

    def add_commit_error
      msg = if new_record?
              _('not authorized to create member')
            else
              _('not authorized to update member')
            end

      member.errors.add(:base, msg)
    end

    def find_or_build_member
      @user = parse_user_param

      @member = if user.is_a?(User)
                  find_or_initialize_member_by_user
                else
                  source.members.build(invite_email: user)
                end

      @member.blocking_refresh = args[:blocking_refresh]
    end

    # This method is used to find users that have been entered into the "Add members" field.
    # These can be the User objects directly, their IDs, their emails, or new emails to be invited.
    def parse_user_param
      case user
      when User
        user
      when Integer
        # might not return anything - this needs enhancement
        User.find_by(id: user) # rubocop:todo CodeReuse/ActiveRecord
      else
        # must be an email or at least we'll consider it one
        source.users_by_emails([user])[user] || user
      end
    end

    def find_or_initialize_member_by_user
      # have to use members and requesters here since project/group limits on requested_at being nil for members and
      # wouldn't be found in `source.members` if it already existed
      # this of course will not treat active invites the same since we aren't searching on email
      source.members_and_requesters.find_or_initialize_by(user_id: user.id) # rubocop:disable CodeReuse/ActiveRecord
    end

    def ldap
      args[:ldap] || false
    end
  end
end

Members::CreatorService.prepend_mod_with('Members::CreatorService')
