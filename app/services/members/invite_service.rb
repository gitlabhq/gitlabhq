# frozen_string_literal: true

module Members
  class InviteService < Members::BaseService
    BlankEmailsError = Class.new(StandardError)
    TooManyEmailsError = Class.new(StandardError)

    def initialize(*args)
      super

      @errors = {}
      @emails = params[:email]&.split(',')&.uniq&.flatten
      @source = params[:source]
    end

    def execute
      validate_emails!

      emails.each(&method(:process_email))
      enqueue_onboarding_progress_action
      result
    rescue BlankEmailsError, TooManyEmailsError => e
      error(e.message)
    end

    private

    attr_reader :source, :errors, :emails, :member_created_namespace_id

    def validate_emails!
      raise BlankEmailsError, s_('AddMember|Email cannot be blank') if emails.blank?

      if user_limit && emails.size > user_limit
        raise TooManyEmailsError, s_("AddMember|Too many users specified (limit is %{user_limit})") % { user_limit: user_limit }
      end
    end

    def user_limit
      limit = params.fetch(:limit, Members::CreateService::DEFAULT_LIMIT)

      limit < 0 ? nil : limit
    end

    def process_email(email)
      return if existing_member?(email)
      return if existing_invite?(email)
      return if existing_request?(email)

      add_member(email)
    end

    def existing_member?(email)
      existing_member = source.members.with_user_by_email(email).exists?

      if existing_member
        errors[email] = s_("AddMember|Already a member of %{source_name}") % { source_name: source.name }
        return true
      end

      false
    end

    def existing_invite?(email)
      existing_invite = source.members.search_invite_email(email).exists?

      if existing_invite
        errors[email] = s_("AddMember|Member already invited to %{source_name}") % { source_name: source.name }
        return true
      end

      false
    end

    def existing_request?(email)
      existing_request = source.requesters.with_user_by_email(email).exists?

      if existing_request
        errors[email] = s_("AddMember|Member cannot be invited because they already requested to join %{source_name}") % { source_name: source.name }
        return true
      end

      false
    end

    def add_member(email)
      new_member = source.add_user(email, params[:access_level], current_user: current_user, expires_at: params[:expires_at])

      if new_member.invalid?
        errors[email] = new_member.errors.full_messages.to_sentence
      else
        after_execute(member: new_member)
        @member_created_namespace_id ||= new_member.namespace_id
      end
    end

    def result
      if errors.any?
        error(errors)
      else
        success
      end
    end

    def enqueue_onboarding_progress_action
      return unless member_created_namespace_id

      Namespaces::OnboardingUserAddedWorker.perform_async(member_created_namespace_id)
    end
  end
end

Members::InviteService.prepend_if_ee('EE::Members::InviteService')
