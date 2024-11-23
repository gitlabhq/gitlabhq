# frozen_string_literal: true

puts Rainbow("Loading the default ApplicationSetting record.").green
settings = ApplicationSetting.current_without_cache

unless settings.present?
  puts Rainbow("Creating the default ApplicationSetting record.").green
  settings = ApplicationSetting.build_from_defaults
end

# Details https://gitlab.com/gitlab-org/gitlab-foss/issues/46241
unless settings.hashed_storage_enabled
  puts Rainbow("Enable hashed storage for every new projects.").green
  settings.hashed_storage_enabled = true
end

unless settings.ci_jwt_signing_key.present?
  puts Rainbow("Generate CI JWT signing key").green
  settings.ci_jwt_signing_key = OpenSSL::PKey::RSA.new(2048).to_pem
end

unless settings.ci_job_token_signing_key.present?
  puts Rainbow("Generate CI Job Token signing key").green
  settings.ci_job_token_signing_key = OpenSSL::PKey::RSA.new(2048).to_pem
end

settings.save!

print '.'
