# frozen_string_literal: true

module Members
  class CreateService < Members::BaseService
    BlankInvitesError = Class.new(StandardError)
    TooManyInvitesError = Class.new(StandardError)
    MembershipLockedError = Class.new(StandardError)

    DEFAULT_INVITE_LIMIT = 100

    attr_reader :membership_locked

    def initialize(*args)
      super

      @errors = []
      @invites = invites_from_params
      @source = params[:source]
      @tasks_to_be_done_members = []
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, create_member_permission(source), source)

      # rubocop:disable Layout/EmptyLineAfterGuardClause
      raise Gitlab::Access::AccessDeniedError if adding_at_least_one_owner &&
        cannot_assign_owner_responsibilities_to_member_in_project?
      # rubocop:enable Layout/EmptyLineAfterGuardClause

      validate_invite_source!
      validate_invitable!

      add_members
      create_tasks_to_be_done
      enqueue_onboarding_progress_action

      publish_event!

      result
    rescue BlankInvitesError, TooManyInvitesError, MembershipLockedError => e
      error(e.message)
    end

    def single_member
      members.last
    end

    private

    attr_reader :source, :errors, :invites, :member_created_namespace_id, :members,
                :tasks_to_be_done_members, :member_created_member_task_id

    def adding_at_least_one_owner
      params[:access_level] == Gitlab::Access::OWNER
    end

    def cannot_assign_owner_responsibilities_to_member_in_project?
      source.is_a?(Project) && !current_user.can?(:manage_owners, source)
    end

    def invites_from_params
      # String, Nil, Array, Integer
      return params[:user_id] if params[:user_id].is_a?(Array)
      return [] unless params[:user_id]

      params[:user_id].to_s.split(',').uniq
    end

    def validate_invite_source!
      raise ArgumentError, s_('AddMember|No invite source provided.') unless invite_source.present?
    end

    def validate_invitable!
      raise BlankInvitesError, blank_invites_message if invites.blank?

      return unless user_limit && invites.size > user_limit

      raise TooManyInvitesError,
            format(s_("AddMember|Too many users specified (limit is %{user_limit})"), user_limit: user_limit)
    end

    def blank_invites_message
      s_('AddMember|No users specified.')
    end

    def add_members
      @members = source.add_members(
        invites,
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user,
        tasks_to_be_done: params[:tasks_to_be_done],
        tasks_project_id: params[:tasks_project_id]
      )

      members.each { |member| process_result(member) }
    end

    def process_result(member)
      existing_errors = member.errors.full_messages

      # calling invalid? clears any errors that were added outside of the
      # rails validation process
      if member.invalid? || existing_errors.present?
        add_error_for_member(member, existing_errors)
      else
        after_execute(member: member)
        @member_created_namespace_id ||= member.namespace_id
      end
    end

    # overridden
    def add_error_for_member(member, existing_errors)
      prefix = "#{member.user.username}: " if member.user.present?

      errors << "#{prefix}#{all_member_errors(member, existing_errors).to_sentence}"
    end

    def all_member_errors(member, existing_errors)
      existing_errors.concat(member.errors.full_messages).uniq
    end

    def after_execute(member:)
      super

      build_tasks_to_be_done_members(member)
      track_invite_source(member)
    end

    def track_invite_source(member)
      Gitlab::Tracking.event(self.class.name,
                             'create_member',
                             label: invite_source,
                             property: tracking_property(member),
                             user: current_user)
    end

    def invite_source
      params[:invite_source]
    end

    def tracking_property(member)
      # ideally invites go down the invite service class instead, but there is nothing that limits an invite
      # from being used in this class and if you send emails as a comma separated list to the api/members
      # endpoint, it will support invites
      member.invite? ? 'net_new_user' : 'existing_user'
    end

    def build_tasks_to_be_done_members(member)
      return unless tasks_to_be_done?(member)

      @tasks_to_be_done_members << member
      # We can take the first `member_task` here, since all tasks will have the same attributes needed
      # for the `TasksToBeDone::CreateWorker`, ie. `project` and `tasks_to_be_done`.
      @member_created_member_task_id ||= member.member_task.id
    end

    def tasks_to_be_done?(member)
      return false if params[:tasks_to_be_done].blank? || params[:tasks_project_id].blank?

      # Only create task issues for existing users. Tasks for new users are created when they signup.
      member.member_task&.valid? && member.user.present?
    end

    def create_tasks_to_be_done
      return unless member_created_member_task_id # signal if there is any work to be done here

      TasksToBeDone::CreateWorker.perform_async(member_created_member_task_id,
                                                current_user.id,
                                                tasks_to_be_done_members.map(&:user_id))
    end

    def user_limit
      limit = params.fetch(:limit, DEFAULT_INVITE_LIMIT)

      limit && limit < 0 ? nil : limit
    end

    def enqueue_onboarding_progress_action
      return unless member_created_namespace_id

      Onboarding::UserAddedWorker.perform_async(member_created_namespace_id)
    end

    def result
      if errors.any?
        error(formatted_errors)
      else
        success
      end
    end

    def formatted_errors
      errors.to_sentence
    end

    def publish_event!
      return unless member_created_namespace_id

      Gitlab::EventStore.publish(
        Members::MembersAddedEvent.new(data: {
          source_id: source.id,
          source_type: source.class.name
        })
      )
    end

    def create_member_permission(source)
      case source
      when Group
        :admin_group_member
      when Project
        :admin_project_member
      else
        raise "Unknown source type: #{source.class}!"
      end
    end
  end
end

Members::CreateService.prepend_mod_with('Members::CreateService')
