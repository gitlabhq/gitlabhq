# frozen_string_literal: true

module Feature
  class Gitaly
    PREFIX = "gitaly_"

    class << self
      def enabled?(feature_flag, project = nil)
        return false unless Feature::FlipperFeature.table_exists?

        Feature.enabled?("#{PREFIX}#{feature_flag}", project, type: :undefined, default_enabled_if_undefined: false)
      rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
        false
      end

      def server_feature_flags(project = nil)
        # We need to check that both the DB connection and table exists
        return {} unless FlipperFeature.database.cached_table_exists?

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
