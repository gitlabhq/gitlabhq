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
      @invites = invites_from_params&.split(',')&.uniq&.flatten
      @source = params[:source]
    end

    def execute
      validate_invite_source!
      validate_invitable!

      add_members
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

    attr_reader :source, :errors, :invites, :member_created_namespace_id, :members

    def invites_from_params
      params[:user_ids]
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
      @members = source.add_users(
        invites,
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user,
        tasks_to_be_done: params[:tasks_to_be_done],
        tasks_project_id: params[:tasks_project_id]
      )

      members.each { |member| process_result(member) }

      create_tasks_to_be_done
    end

    def process_result(member)
      if member.invalid?
        add_error_for_member(member)
      else
        after_execute(member: member)
        @member_created_namespace_id ||= member.namespace_id
      end
    end

    def add_error_for_member(member)
      prefix = "#{member.user.username}: " if member.user.present?

      errors << "#{prefix}#{member.errors.full_messages.to_sentence}"
    end

    def after_execute(member:)
      super

      track_invite_source(member)
    end

    def track_invite_source(member)
      Gitlab::Tracking.event(self.class.name, 'create_member', label: invite_source, property: tracking_property(member), user: current_user)
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

    def create_tasks_to_be_done
      return if params[:tasks_to_be_done].blank? || params[:tasks_project_id].blank?

      valid_members = members.select { |member| member.valid? && member.member_task.valid? }
      return unless valid_members.present?

      # We can take the first `member_task` here, since all tasks will have the same attributes needed
      # for the `TasksToBeDone::CreateWorker`, ie. `project` and `tasks_to_be_done`.
      member_task = valid_members[0].member_task
      TasksToBeDone::CreateWorker.perform_async(member_task.id, current_user.id, valid_members.map(&:user_id))
    end

    def user_limit
      limit = params.fetch(:limit, DEFAULT_INVITE_LIMIT)

      limit && limit < 0 ? nil : limit
    end

    def enqueue_onboarding_progress_action
      return unless member_created_namespace_id

      Namespaces::OnboardingUserAddedWorker.perform_async(member_created_namespace_id)
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
      Gitlab::EventStore.publish(
        Members::MembersAddedEvent.new(data: {
          source_id: source.id,
          source_type: source.class.name
        })
      )
    end
  end
end

Members::CreateService.prepend_mod_with('Members::CreateService')
