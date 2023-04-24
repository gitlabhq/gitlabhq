# frozen_string_literal: true

# The purpose of this code is to set the migrations path
# for the Geo tracking database and the embedding database.
module Gitlab
  module Patch
    module DatabaseConfig
      extend ActiveSupport::Concern

      def database_configuration
        super.to_h do |env, configs|
          if Gitlab.ee?
            ee_databases = %w[embedding geo]

            ee_databases.each do |ee_db_name|
              next unless configs.key?(ee_db_name)

              migrations_paths = Array(configs[ee_db_name]['migrations_paths'])
              migrations_paths << File.join('ee', 'db', ee_db_name, 'migrate') if migrations_paths.empty?
              migrations_paths << File.join('ee', 'db', ee_db_name, 'post_migrate') unless ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS']

              configs[ee_db_name]['migrations_paths'] = migrations_paths.uniq
              configs[ee_db_name]['schema_migrations_path'] = File.join('ee', 'db', ee_db_name, 'schema_migrations') if configs[ee_db_name]['schema_migrations_path'].blank?
            end
          end

          [env, configs]
        end
      end
    end
  end
end
