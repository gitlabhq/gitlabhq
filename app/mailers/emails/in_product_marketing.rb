# frozen_string_literal: true

module Emails
  module InProductMarketing
    FROM_ADDRESS = 'GitLab <team@gitlab.com>'
    CUSTOM_HEADERS = {
      from: FROM_ADDRESS,
      reply_to: FROM_ADDRESS,
      'X-Mailgun-Track' => 'yes',
      'X-Mailgun-Track-Clicks' => 'yes',
      'X-Mailgun-Track-Opens' => 'yes',
      'X-Mailgun-Tag' => 'marketing'
    }.freeze

    def in_product_marketing_email(recipient_id, group_id, track, series)
      group = Group.find(group_id)
      user = User.find(recipient_id)
      email = user.notification_email_for(group)
      @message = Gitlab::Email::Message::InProductMarketing.for(track).new(group: group, user: user, series: series)

      mail_to(to: email, subject: @message.subject_line)
    end

    private

    def mail_to(to:, subject:)
      custom_headers = Gitlab.com? ? CUSTOM_HEADERS : {}
      mail(to: to, subject: subject, **custom_headers) do |format|
        format.html do
          @message.format = :html

          render layout: nil
        end

        format.text do
          @message.format = :text

          render layout: nil
        end
      end
    end
  end
end
