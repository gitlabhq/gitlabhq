# frozen_string_literal: true

module Members
  class InviteService < Members::CreateService
    extend ::Gitlab::Utils::Override

    def initialize(*args)
      super

      @errors = {}
    end

    private

    alias_method :formatted_errors, :errors

    def invites_from_params
      params[:email]
    end

    def validate_invites!
      super

      # we need the below due to add_users hitting Members::CreatorService.parse_users_list and ignoring invalid emails
      # ideally we wouldn't need this, but we can't really change the add_users method
      valid, invalid = invites.partition { |email| Member.valid_email?(email) }
      @invites = valid

      invalid.each { |email| errors[email] = s_('AddMember|Invite email is invalid') }
    end

    override :blank_invites_message
    def blank_invites_message
      s_('AddMember|Emails cannot be blank')
    end

    override :add_error_for_member
    def add_error_for_member(member)
      errors[invite_email(member)] = member.errors.full_messages.to_sentence
    end

    def invite_email(member)
      member.invite_email || member.user.email
    end
  end
end
