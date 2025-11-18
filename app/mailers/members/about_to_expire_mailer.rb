# frozen_string_literal: true

module Members
  class AboutToExpireMailer < ApplicationMailer
    helper EmailsHelper

    helper_method :member, :member_source, :user, :days_to_expire

    layout 'mailer'

    def email
      return if member.blank? || member.expires_at.blank? || days_to_expire <= 0
      return unless member.notifiable?(:mention)

      mail_with_locale(
        to: user.notification_email_for(member_source.notification_group),
        subject: EmailsHelper.subject_with_prefix_and_suffix([email_subject_text])
      )
    end

    private

    delegate :user, to: :member
    delegate :source, to: :member, prefix: true

    def member
      params[:member]
    end

    def days_to_expire
      @days_to_expire ||= (member.expires_at - Date.today).to_i # rubocop:disable Rails/Date -- maintain original functionality
    end

    def email_subject_text
      format(s_('AboutToExpireEmail|Your membership will expire in %{days_to_expire} days'),
        days_to_expire: days_to_expire)
    end
  end
end
