# frozen_string_literal: true

class Feature
  class Gitaly
    PREFIX = "gitaly_"

    class << self
      def enabled?(feature_flag, project = nil)
        return false unless Feature::FlipperFeature.table_exists?

        Feature.enabled?("#{PREFIX}#{feature_flag}", project)
      rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
        false
      end

      def server_feature_flags(project = nil)
        # We need to check that both the DB connection and table exists
        return {} unless ::Gitlab::Database.cached_table_exists?(FlipperFeature.table_name)

        Feature.persisted_names
          .select { |f| f.start_with?(PREFIX) }
          .to_h do |f|
          flag = f.delete_prefix(PREFIX)

          ["gitaly-feature-#{flag.tr('_', '-')}", enabled?(flag, project).to_s]
        end
      end
    end
  end
end
