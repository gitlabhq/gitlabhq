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

    private

    def mail_to(to:, subject:)
      custom_headers = Gitlab.com? ? CUSTOM_HEADERS : {}
      mail_with_locale(to: to, subject: subject, **custom_headers) do |format|
        format.html do
          @message.format = :html

          render layout: 'in_product_marketing_mailer'
        end

        format.text do
          @message.format = :text

          render layout: nil
        end
      end
    end
  end
end

Emails::InProductMarketing.prepend_mod
