# frozen_string_literal: true

module Emails
  module InProductMarketing
    include InProductMarketingHelper

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
      @track = track
      @series = series
      @group = Group.find(group_id)

      email = User.find(recipient_id).notification_email_for(@group)
      subject = subject_line(track, series)
      mail_to(to: email, subject: subject)
    end

    private

    def mail_to(to:, subject:)
      custom_headers = Gitlab.com? ? CUSTOM_HEADERS : {}
      mail(to: to, subject: subject, **custom_headers) do |format|
        format.html { render layout: nil }
        format.text { render layout: nil }
      end
    end
  end
end
