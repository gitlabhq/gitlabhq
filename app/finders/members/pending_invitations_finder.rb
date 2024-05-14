# frozen_string_literal: true

module Members
  class PendingInvitationsFinder
    def initialize(invite_emails)
      @invite_emails = invite_emails
    end

    def execute
      Member.with_case_insensitive_invite_emails(invite_emails)
            .invite
            .distinct_on_source_and_case_insensitive_invite_email
            .order_updated_desc
    end

    private

    attr_reader :invite_emails
  end
end
