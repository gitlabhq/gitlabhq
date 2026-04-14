# frozen_string_literal: true

module Cells
  module Claims
    class BulkClaimService < BaseService
      # @param model [Class] The ActiveRecord model class (e.g. RedirectRoute).
      #   Must include Cells::Claimable.
      # @param attribute [Symbol] The claimable attribute to claim (e.g. :path)
      # @param records [ActiveRecord::Relation, Array<ActiveRecord::Base>] The
      #   records to create claims for. Each record must respond to the attribute
      #   and have a persisted primary key.
      def initialize(model:, attribute:, records:)
        @model = model
        @attribute = attribute
        @records = records
      end

      def execute
        unless claimable_model?
          Gitlab::AppLogger.warn(
            class: self.class.name,
            message: "#{model.name} model is not claimable, skipping bulk claim",
            feature_category: :cell
          )
          return { created: 0, chunk_count: 0 }
        end

        return { created: 0, chunk_count: 0 } unless enabled?

        claim_metadata = build_claim_metadata
        return { created: 0, chunk_count: 0 } if claim_metadata.empty?

        chunk_count = commit_changes(creates: claim_metadata)
        created_count = claim_metadata.size

        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Cells::Claims::BulkClaimService batch processed",
          table_name: model.table_name,
          created: created_count,
          chunk_count: chunk_count,
          cell_id: claim_service.cell_id,
          feature_category: :cell
        )

        { created: created_count, chunk_count: chunk_count }
      end

      private

      attr_reader :attribute, :records

      def enabled?
        return false unless Gitlab.config.cell.enabled

        attribute_config = model.cells_claims_attributes[attribute]
        return false unless attribute_config

        model.cells_claims_enabled_for_attribute?(attribute_config)
      end

      def build_claim_metadata
        records.filter_map { |record| record.cells_claims_metadata_for_attribute(attribute) }
      end
    end
  end
end
