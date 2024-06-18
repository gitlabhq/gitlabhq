# frozen_string_literal: true

module Members
  class InviteService < Members::CreateService
    extend ::Gitlab::Utils::Override

    def initialize(*args)
      super

      @invites += parsed_emails

      @errors = {}
    end

    private

    alias_method :formatted_errors, :errors

    def parsed_emails
      # can't put this in the initializer since `invites_from_params` is called in super class
      # and needs it
      @parsed_emails ||= (formatted_param(params[:email]) || [])
    end

    def formatted_param(parameter)
      parameter&.split(',')&.uniq&.flatten
    end

    def validate_invitable!
      super

      return if params[:email].blank?

      # we need the below due to add_member hitting Members::CreatorService.parse_users_list and ignoring invalid emails
      # ideally we wouldn't need this, but we can't really change the add_members method
      invalid_emails.each { |email| errors[email] = s_('AddMember|Invite email is invalid') }
    end

    def invalid_emails
      parsed_emails.each_with_object([]) do |email, invalid|
        next if Member.valid_email?(email)

        invalid << email
        @invites.delete(email)
      end
    end

    override :blank_invites_message
    def blank_invites_message
      s_('AddMember|Invites cannot be blank')
    end

    override :add_error_for_member
    def add_error_for_member(member, existing_errors)
      errors[invited_object(member)] = all_member_errors(member, existing_errors).to_sentence
    end

    def invited_object(member)
      if member.invite_email
        # We reverse here as the case with duplicate emails on the same request the last one is likely the issue as
        # the first one will be committed to db first and so it will be the last instance of that email that has
        # the error.
        # For updates, they can still have an upper case email, so we need compare case insensitively on the both sides
        # of this find.
        return invites.reverse.find { |email| email.casecmp?(member.invite_email) }
      end

      # There is a case where someone was invited by email, but the `user` record exists.
      # The member record returned will not have an invite_email attribute defined since
      # the CreatorService finds `user` record sometimes by email.
      # At that point we lose the info of whether this invite was done by `user` or by email.
      # Here we will give preference to check invites by user_id first.
      # There is also a case where a user could be invited by their email and
      # at the same time via the API in the same request.
      # This would would mean the same user is invited as user_id and email.
      # However, that isn't as likely from the UI at least since the token generator checks
      # for that case and doesn't allow email being used if the user exists as a record already.
      if member.user_id.to_s.in?(invites)
        member.user.username
      else
        # We find the correct match here case insensitively user.all_emails since it can
        # have an uppercase email for private_commit_email.
        # We need to downcase our invites against the rest since the user could input
        # uppercase invite and we need to find the case insensitive match on that.
        invites.find { |email| email.downcase.in?(member.user.all_emails.map(&:downcase)) }
      end
    end
  end
end

Members::InviteService.prepend_mod
