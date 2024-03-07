# frozen_string_literal: true

puts "Loading the default ApplicationSetting record.".color(:green)
settings = ApplicationSetting.current_without_cache

unless settings.present?
  puts "Creating the default ApplicationSetting record.".color(:green)
  settings = ApplicationSetting.build_from_defaults
end

# Details https://gitlab.com/gitlab-org/gitlab-foss/issues/46241
unless settings.hashed_storage_enabled
  puts "Enable hashed storage for every new projects.".color(:green)
  settings.hashed_storage_enabled = true
end

unless settings.ci_jwt_signing_key.present?
  puts "Generate CI JWT signing key".color(:green)
  settings.ci_jwt_signing_key = OpenSSL::PKey::RSA.new(2048).to_pem
end

settings.save!

print '.'
