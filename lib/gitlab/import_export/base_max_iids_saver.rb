# frozen_string_literal: true

module Gitlab
  module ImportExport
    # Base class for saving max IIDs during export.
    #
    # Subclasses must implement:
    # - .resource_queries: Hash mapping resource keys to lambdas that compute max IID
    class BaseMaxIidsSaver
      include DurationMeasuring

      def self.resource_queries
        raise NotImplementedError, "#{name} must implement .resource_queries"
      end

      def initialize(exportable:, shared:)
        @exportable = exportable
        @shared = shared
      end

      def save
        with_duration_measuring do
          json_writer = Gitlab::ImportExport::Json::NdjsonWriter.new(@shared.export_path)
          json_writer.write_attributes('max_iids', compute_max_iids)
          true
        end
      rescue StandardError => e
        @shared.error(e)
        false
      end

      private

      attr_reader :exportable

      def compute_max_iids
        self.class.resource_queries.each_with_object({}) do |(resource, query), result|
          max = query.call(exportable)
          result[resource.to_s] = max if max
        end
      end
    end
  end
end
