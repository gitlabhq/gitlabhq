# frozen_string_literal: true

module Gitlab
  module Database
    module Capture
      # Only evaluated when query analyzers are enabled at request/job start,
      # never per query, where a DB-backed lookup is unsafe.
      def self.enabled?
        ::Feature::FlipperFeature.table_exists? &&
          ::Feature.enabled?(:database_capture, ::Feature.current_pod, type: :ops)
      end
    end
  end
end
