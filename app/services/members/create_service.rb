# frozen_string_literal: true

module Members
  class CreateService < Members::BaseService
    BlankInvitesError = Class.new(StandardError)
    TooManyInvitesError = Class.new(StandardError)

    DEFAULT_INVITE_LIMIT = 100

    def initialize(*args)
      super

      @errors = []
      @invites = invites_from_params&.split(',')&.uniq&.flatten
      @source = params[:source]
    end

    def execute
      validate_invite_source!
      validate_invites!

      add_members
      enqueue_onboarding_progress_action
      result
    rescue BlankInvitesError, TooManyInvitesError => e
      error(e.message)
    end

    private

    attr_reader :source, :errors, :invites, :member_created_namespace_id

    def invites_from_params
      params[:user_ids]
    end

    def validate_invite_source!
      raise ArgumentError, s_('AddMember|No invite source provided.') unless invite_source.present?
    end

    def validate_invites!
      raise BlankInvitesError, blank_invites_message if invites.blank?

      return unless user_limit && invites.size > user_limit

      raise TooManyInvitesError,
            format(s_("AddMember|Too many users specified (limit is %{user_limit})"), user_limit: user_limit)
    end

    def blank_invites_message
      s_('AddMember|No users specified.')
    end

    def add_members
      members = source.add_users(
        invites,
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user
      )

      members.each { |member| process_result(member) }
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
  end
end

Members::CreateService.prepend_mod_with('Members::CreateService')
