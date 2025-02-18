# frozen_string_literal: true

module Gitlab
  module Metrics
    module SecurityScanSlis
      include Gitlab::Metrics::SliConfig

      sidekiq_enabled!

      class << self
        def initialize_slis!
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:security_scan, possible_labels)
        end

        def error_rate
          Gitlab::Metrics::Sli::ErrorRate[:security_scan]
        end

        private

        def possible_labels
          Enums::Vulnerability.report_type_feature_categories.map do |scan_type, feature_category|
            { scan_type: scan_type, feature_category: feature_category }
          end
        end
      end
    end
  end
end
