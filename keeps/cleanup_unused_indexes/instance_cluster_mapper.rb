# frozen_string_literal: true

require 'gitlab/housekeeper/keep'

module Keeps
  class CleanupUnusedIndexes < ::Gitlab::Housekeeper::Keep
    # Maps a `gitlab_schema` to the Mimir `type` label of its Patroni cluster.
    # The `patroni-<db>` naming is operator-defined in gitlab-com/runbooks;
    # unknown schemas fall back to the main `patroni` cluster.
    class InstanceClusterMapper
      DEFAULT_TYPE = 'patroni'

      def for_schema(gitlab_schema)
        return DEFAULT_TYPE if gitlab_schema.nil?

        @cache ||= {}
        key = gitlab_schema.to_s
        @cache[key] ||= compute_for_schema(key)
      end

      private

      def compute_for_schema(gitlab_schema)
        db_info = Gitlab::Database.all_database_connections.values.find do |db|
          db.gitlab_schemas.include?(gitlab_schema.to_sym)
        end
        db_name = db_info&.name&.to_s

        return DEFAULT_TYPE if db_name.nil? || db_name == Gitlab::Database::MAIN_DATABASE_NAME

        "patroni-#{db_name}"
      end
    end
  end
end
