module EE
  module Gitlab
    module Database
      extend ::Gitlab::Utils::Override

      override :add_post_migrate_path_to_rails
      def add_post_migrate_path_to_rails(force: false)
        super

        migrate_paths = Rails.application.config.paths['db/migrate'].to_a
        migrate_paths.each do |migrate_path|
          relative_migrate_path = Pathname.new(migrate_path).realpath(Rails.root).relative_path_from(Rails.root)
          ee_migrate_path = Rails.root.join('ee/', relative_migrate_path)

          next if relative_migrate_path.to_s.start_with?('ee/') ||
              Rails.application.config.paths['db/migrate'].include?(ee_migrate_path.to_s)

          Rails.application.config.paths['db/migrate'] << ee_migrate_path.to_s
          ActiveRecord::Migrator.migrations_paths << ee_migrate_path.to_s
        end
      end
    end
  end
end
