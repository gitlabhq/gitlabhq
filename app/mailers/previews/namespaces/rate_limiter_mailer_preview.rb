# frozen_string_literal: true

module Namespaces
  class RateLimiterMailerPreview < ActionMailer::Preview
    def project_or_group_emails
      project = Project.last
      user = User.last

      Namespaces::RateLimiterMailer.project_or_group_emails(project, user.email)
    end
  end
end
