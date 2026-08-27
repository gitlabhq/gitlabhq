# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    namespace :pg_ash do
      desc "GitLab | DB | Install pg_ash on the main database"
      task install: :environment do
        installer = Gitlab::Database::PgAsh::Installer.new
        previous_version = installer.installed_version

        begin
          version = installer.install
        rescue Gitlab::Database::PgAsh::Installer::PermissionError,
          Gitlab::Database::PgAsh::Installer::VersionMismatchError => e
          abort(e.message)
        end

        puts(previous_version.nil? ? "pg_ash #{version} installed." : "pg_ash #{version} re-applied.")
      end

      desc "GitLab | DB | Remove pg_ash and all of its data from the main database"
      task uninstall: :environment do
        if Gitlab::Database::PgAsh::Installer.new.uninstall
          puts "pg_ash removed."
        else
          puts "pg_ash is not installed."
        end
      end

      desc "GitLab | DB | Show pg_ash status on the main database"
      task status: :environment do
        status = Gitlab::Database::PgAsh::Installer.new.status

        if status
          status.each { |metric, value| puts format('%-28<metric>s %<value>s', metric: metric, value: value) }
        else
          puts "pg_ash is not installed."
        end
      end
    end
  end
end
