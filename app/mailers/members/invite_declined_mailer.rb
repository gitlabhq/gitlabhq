# frozen_string_literal: true

module Members
  class InviteDeclinedMailer < ApplicationMailer
    helper EmailsHelper

    helper_method :member_source, :member_invite_email

    layout 'mailer'

    def email
      return unless valid_to_email?

      mail_with_locale(
        to: member_created_by.notification_email_for(member_source.notification_group),
        subject: EmailsHelper.subject_with_suffix(['Invitation declined'])
      )
    end

    private

    delegate :source, :invite_email, :created_by, to: :member, prefix: true
    delegate :user, to: :member

    def valid_to_email?
      # Must always send, regardless of project/namespace configuration since it's a
      # response to the user's action.
      member && member_created_by.present?
    end

    def member
      params[:member]
    end
  end
end
