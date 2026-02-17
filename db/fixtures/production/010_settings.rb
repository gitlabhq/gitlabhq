def save(settings, topic)
  if settings.save
    puts Rainbow("Saved #{topic}").green
  else
    puts Rainbow("Could not save #{topic}").red
    puts
    settings.errors.full_messages.map do |message|
      puts Rainbow("--> #{message}").red
    end
    puts
    exit(1)
  end
end

# NOTE: Will be removed in 18.0, see https://gitlab.com/gitlab-org/gitlab/-/issues/453949
if ENV['GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN'].present?
  settings = Gitlab::CurrentSettings.current_application_settings
  settings.set_runners_registration_token(ENV['GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN'])
  save(settings, 'Runner Registration Token')
end

if ENV['GITLAB_PROMETHEUS_METRICS_ENABLED'].present?
  settings = Gitlab::CurrentSettings.current_application_settings
  value = Gitlab::Utils.to_boolean(ENV['GITLAB_PROMETHEUS_METRICS_ENABLED']) || false
  settings.prometheus_metrics_enabled = value
  save(settings, 'Prometheus metrics enabled flag')
end

settings = Gitlab::CurrentSettings.current_application_settings
settings.ci_jwt_signing_key = OpenSSL::PKey::RSA.new(2048).to_pem
save(settings, 'CI JWT signing key')

settings = Gitlab::CurrentSettings.current_application_settings
settings.ci_job_token_signing_key = OpenSSL::PKey::RSA.new(2048).to_pem
save(settings, 'CI Job Token signing key')
