# frozen_string_literal: true

module Namespaces
  class RateLimiterMailer < ApplicationMailer
    layout 'empty_mailer'

    helper EmailsHelper

    def project_or_group_emails(project_or_group, recipient)
      @project_or_group = project_or_group

      headers = {
        to: recipient,
        subject: [project_or_group.name, 'Notifications temporarily disabled'].join(' | ')
      }

      mail_with_locale(headers)
    end
  end
end
