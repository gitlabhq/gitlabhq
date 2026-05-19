# frozen_string_literal: true

module Cells
  module Claims
    class BulkClaimService < BaseService
      # @param model [Class] The ActiveRecord model class (e.g. RedirectRoute).
      #   Must include Cells::Claimable.
      # @param attribute [Symbol] The claimable attribute to claim (e.g. :path)
      # @param creates [Array<Hash>] Claim metadata hashes for records to create
      #   claims for. Each hash must contain the full claim metadata structure
      #   expected by BaseService#commit_changes.
      # @param destroys [Array<Hash>] Claim metadata hashes for records to destroy
      #   claims for. Each hash must contain the full claim metadata structure
      #   expected by BaseService#commit_changes.
      def initialize(model:, attribute:, creates: [], destroys: [])
        @model = model
        @attribute = attribute
        @creates = creates
        @destroys = destroys
      end

      def execute
        unless claimable_model?
          Gitlab::AppLogger.warn(
            class: self.class.name,
            message: "#{model.name} model is not claimable, skipping bulk claim",
            feature_category: :cell
          )
          return { created: 0, destroyed: 0, chunk_count: 0 }
        end

        return { created: 0, destroyed: 0, chunk_count: 0 } if creates.empty? && destroys.empty?

        chunk_count = commit_changes(creates: creates, destroys: destroys)
        created_count = creates.size
        destroyed_count = destroys.size

        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Cells::Claims::BulkClaimService batch processed",
          table_name: model.table_name,
          created: created_count,
          destroyed: destroyed_count,
          chunk_count: chunk_count,
          cell_id: claim_service.cell_id,
          feature_category: :cell
        )

        { created: created_count, destroyed: destroyed_count, chunk_count: chunk_count }
      end

      private

      attr_reader :attribute, :creates, :destroys
    end
  end
end
