# Post deployment migrations are included by default. This file must be loaded
# before other initializers as Rails may otherwise memoize a list of migrations
# excluding the post deployment migrations.
unless ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS']
  Rails.application.config.paths['db'].each do |db_path|
    path = Rails.root.join(db_path, 'post_migrate').to_s

    Rails.application.config.paths['db/migrate'] << path

    # Rails memoizes migrations at certain points where it won't read the above
    # path just yet. As such we must also update the following list of paths.
    ActiveRecord::Migrator.migrations_paths << path
  end
end

migrate_paths = Rails.application.config.paths['db/migrate'].to_a
migrate_paths.each do |migrate_path|
  absolute_migrate_path = Pathname.new(migrate_path).realpath(Rails.root)
  ee_migrate_path = Rails.root.join('ee/', absolute_migrate_path.relative_path_from(Rails.root))

  Rails.application.config.paths['db/migrate'] << ee_migrate_path.to_s
  ActiveRecord::Migrator.migrations_paths << ee_migrate_path.to_s
end
