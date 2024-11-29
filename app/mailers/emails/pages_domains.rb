# frozen_string_literal: true

module Emails
  module PagesDomains
    def pages_domain_enabled_email(domain, recipient)
      @domain = domain
      @project = domain.project

      email_with_layout(
        to: recipient.notification_email_for(@project.group),
        subject: subject("GitLab Pages domain '#{domain.domain}' has been enabled")
      )
    end

    def pages_domain_disabled_email(domain, recipient)
      @domain = domain
      @project = domain.project

      email_with_layout(
        to: recipient.notification_email_for(@project.group),
        subject: subject("GitLab Pages domain '#{domain.domain}' has been disabled")
      )
    end

    def pages_domain_verification_succeeded_email(domain, recipient)
      @domain = domain
      @project = domain.project

      email_with_layout(
        to: recipient.notification_email_for(@project.group),
        subject: subject("Verification succeeded for GitLab Pages domain '#{domain.domain}'")
      )
    end

    def pages_domain_verification_failed_email(domain, recipient)
      @domain = domain
      @project = domain.project

      email_with_layout(
        to: recipient.notification_email_for(@project.group),
        subject: subject("ACTION REQUIRED: Verification failed for GitLab Pages domain '#{domain.domain}'")
      )
    end

    def pages_domain_auto_ssl_failed_email(domain, recipient)
      @domain = domain
      @project = domain.project

      subject_text = _(
        "ACTION REQUIRED: Something went wrong while obtaining the Let's Encrypt certificate for " \
          "GitLab Pages domain '%{domain}'"
      ) % { domain: domain.domain }
      email_with_layout(
        to: recipient.notification_email_for(@project.group),
        subject: subject(subject_text)
      )
    end
  end
end
