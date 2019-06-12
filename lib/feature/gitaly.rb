class Feature
  class Gitaly
    CATFILE_CACHE = 'catfile-cache'.freeze

    # Server feature flags should use '_' to separate words.
    SERVER_FEATURE_FLAGS = [CATFILE_CACHE].freeze

    class << self
      def enabled?(feature_flag)
        Feature::FlipperFeature.table_exists? && Feature.enabled?("gitaly_#{feature_flag}")
      rescue ActiveRecord::NoDatabaseError
        false
      end

      def server_feature_flags
        @server_feature_flags ||=
          begin
            SERVER_FEATURE_FLAGS.map do |f|
              ["gitaly-feature-#{f.tr('_', '-')}", enabled?(f).to_s]
            end.to_h
          end
      end
    end
  end
end
