# Email forcibly included in the standard checks, but the email health check
# doesn't support the full range of SMTP options, which can result in failures
# for valid SMTP configurations.
# Overwrite the HealthCheck's detection of whether email is configured
# in order to avoid the email check during standard checks
module HealthCheck
  class Utils
    def self.mailer_configured?
      false
    end
  end
end

HealthCheck.setup do |config|
  config.standard_checks = ['database', 'migrations', 'cache']
  config.full_checks = ['database', 'migrations', 'cache']
end
