# frozen_string_literal: true

# The purpose of this code is to set the migrations path
# for the Geo tracking database.
module Gitlab
  module Patch
    module DatabaseConfig
      extend ActiveSupport::Concern

      def database_configuration
        super.to_h do |env, configs|
          if Gitlab.ee?
            if configs.key?("geo")
              migrations_paths = Array(configs["geo"]["migrations_paths"])
              migrations_paths << "ee/db/geo/migrate" if migrations_paths.empty?
              migrations_paths << "ee/db/geo/post_migrate" unless ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS']

              configs["geo"]["migrations_paths"] = migrations_paths.uniq
              configs["geo"]["schema_migrations_path"] = "ee/db/geo/schema_migrations" if configs["geo"]["schema_migrations_path"].blank?
            end
          end

          [env, configs]
        end
      end
    end
  end
end
