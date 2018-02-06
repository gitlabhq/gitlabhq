module Emails
  module PagesDomains
    def pages_domain_enabled_email(domain, recipient)
      @domain = domain
      @project = domain.project

      mail(
        to: recipient.notification_email,
        subject: subject("GitLab Pages domain '#{domain.domain}' has been enabled")
      )
    end

    def pages_domain_disabled_email(domain, recipient)
      @domain = domain
      @project = domain.project

      mail(
        to: recipient.notification_email,
        subject: subject("GitLab Pages domain '#{domain.domain}' has been disabled")
      )
    end

    def pages_domain_verification_succeeded_email(domain, recipient)
      @domain = domain
      @project = domain.project

      mail(
        to: recipient.notification_email,
        subject: subject("Verification succeeded for GitLab Pages domain '#{domain.domain}'")
      )
    end

    def pages_domain_verification_failed_email(domain, recipient)
      @domain = domain
      @project = domain.project

      mail(
        to: recipient.notification_email,
        subject: subject("ACTION REQUIRED: Verification failed for GitLab Pages domain '#{domain.domain}'")
      )
    end
  end
end
