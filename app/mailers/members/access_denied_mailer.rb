# frozen_string_literal: true

module Members
  class AccessDeniedMailer < ApplicationMailer
    helper EmailsHelper

    helper_method :member_source, :source_hidden?

    layout 'mailer'

    def email
      return unless member.notifiable?(:subscription)

      mail_with_locale(
        to: user.notification_email_for(member_source.notification_group),
        subject: EmailsHelper.subject_with_suffix([email_subject_text])
      )
    end

    private

    delegate :source, to: :member, prefix: true
    delegate :user, to: :member

    def source_hidden?
      !member_source.readable_by?(user)
    end

    def member
      params[:member]
    end

    def email_subject_text
      human_name = source_hidden? ? 'Hidden' : member_source.human_name

      "Access to the #{human_name} #{member_source.model_name.singular} was denied"
    end
  end
end
