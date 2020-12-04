# frozen_string_literal: true

module Members
  class InvitationReminderEmailService
    include Gitlab::Utils::StrongMemoize

    attr_reader :invitation

    MAX_INVITATION_LIFESPAN = 14.0
    REMINDER_RATIO = [2, 5, 10].freeze

    def initialize(invitation)
      @invitation = invitation
    end

    def execute
      reminder_index = days_on_which_to_send_reminders.index(days_after_invitation_sent)
      return unless reminder_index

      invitation.send_invitation_reminder(reminder_index)
    end

    private

    def days_after_invitation_sent
      (Date.today - invitation.created_at.to_date).to_i
    end

    def days_on_which_to_send_reminders
      # Don't send any reminders if the invitation has expired or expires today
      return [] if invitation.expires_at && invitation.expires_at <= Date.today

      # Calculate the number of days on which to send reminders based on the MAX_INVITATION_LIFESPAN and the REMINDER_RATIO
      REMINDER_RATIO.map { |number_of_days| ((number_of_days * invitation_lifespan_in_days) / MAX_INVITATION_LIFESPAN).ceil }.uniq
    end

    def invitation_lifespan_in_days
      # When the invitation lifespan is more than 14 days or does not expire, send the reminders within 14 days
      strong_memoize(:invitation_lifespan_in_days) do
        if invitation.expires_at
          [(invitation.expires_at - invitation.created_at.to_date).to_i, MAX_INVITATION_LIFESPAN].min
        else
          MAX_INVITATION_LIFESPAN
        end
      end
    end
  end
end
