# frozen_string_literal: true

puts "Creating the default ApplicationSetting record.".color(:green)
ApplicationSetting.create_from_defaults

# Details https://gitlab.com/gitlab-org/gitlab-foss/issues/46241
puts "Enable hashed storage for every new projects.".color(:green)
ApplicationSetting.current_without_cache.update!(hashed_storage_enabled: true)

puts "Generate CI JWT signing key".color(:green)
ApplicationSetting.current_without_cache.update!(ci_jwt_signing_key: OpenSSL::PKey::RSA.new(2048).to_pem)

print '.'
