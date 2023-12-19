# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    namespace :decomposition do
      desc 'Migrate single database to two database setup'
      task migrate: :environment do
        Gitlab::Database::Decomposition::Migrate.new(backup_base_location: ENV['BACKUP_BASE_LOCATION']).process!

        puts "Database migration finished!"
      rescue Gitlab::Database::Decomposition::MigrateError => e
        puts e.message
        exit 1
      end
    end
  end
end
