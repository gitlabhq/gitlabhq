# frozen_string_literal: true

# Enable hashed storage, in development mode, for all projects by default.
Gitlab::Seeder.quiet do
  ApplicationSetting.create_from_defaults unless ApplicationSetting.current_without_cache
  ApplicationSetting.current_without_cache.update!(hashed_storage_enabled: true)
  print '.'
end
