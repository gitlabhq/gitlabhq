# We want to enable hashed storage for every new project in development
# Details https://gitlab.com/gitlab-org/gitlab-ce/issues/46241
Gitlab::Seeder.quiet do
  ApplicationSetting.create_from_defaults unless ApplicationSetting.current_without_cache
  ApplicationSetting.current_without_cache.update!(hashed_storage_enabled: true)
  print '.'
end
