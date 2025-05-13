# frozen_string_literal: true

module Members
  class AccessRequestedMailer < ApplicationMailer
    helper EmailsHelper

    helper_method :member_source, :member, :target_type

    layout 'mailer'

    def email
      return unless valid_to_email?

      mail_with_locale(
        to: recipient.notification_email_for(member_source.notification_group),
        subject: EmailsHelper.subject_with_prefix_and_suffix([email_subject_text])
      )
    end

    private

    delegate :source, to: :member, prefix: true

    def valid_to_email?
      if member.blank?
        Gitlab::AppLogger.info('Tried to send an access requested for an invalid member.')
        return false
      end

      true
    end

    def target_type
      member_source.model_name.singular
    end

    def member
      params[:member]
    end

    def recipient
      params[:recipient]
    end

    def email_subject_text
      "Request to join the #{member_source.human_name} #{member_source.model_name.singular}"
    end
  end
end
