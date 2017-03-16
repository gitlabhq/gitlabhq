current_version = Gitlab::VersionInfo.parse(Gitlab::VERSION)

past_version_paths = Dir.glob(Rails.root.join('db', 'release_migrations', '*').to_s).select do |path|
  version_string = path.match(%r{db/release_migrations/((\d+)\.(\d+)\.(\d+))})[1]
  version = Gitlab::VersionInfo.parse(version_string)
  version <= current_version
end

migrate_paths = past_version_paths.map { |path| File.join(path, 'migrate') }

Rails.application.config.paths['db/migrate'].concat(migrate_paths)

# Rails memoizes migrations at certain points where it won't read the above
# path just yet. As such we must also update the following list of paths.
ActiveRecord::Migrator.migrations_paths.concat(migrate_paths)

# Post deployment migrations are included by default. This file must be loaded
# before other initializers as Rails may otherwise memoize a list of migrations
# excluding the post deployment migrations.
unless ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS']
  post_migrate_paths = past_version_paths.map { |path| File.join(path, 'post_migrate') }
  post_migrate_paths << Rails.root.join('db', 'post_migrate').to_s

  Rails.application.config.paths['db/migrate'].concat(post_migrate_paths)

  # Rails memoizes migrations at certain points where it won't read the above
  # path just yet. As such we must also update the following list of paths.
  ActiveRecord::Migrator.migrations_paths.concat(post_migrate_paths)
end
