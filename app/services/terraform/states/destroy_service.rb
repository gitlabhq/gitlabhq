# frozen_string_literal: true

module Terraform
  module States
    class DestroyService
      def initialize(state)
        @state = state
      end

      def execute
        return unless state.deleted_at?

        return if delayed_deletion_active? && state.within_grace_period?

        state.versions.each_batch(column: :version) do |batch|
          process_batch(batch)
        end

        state.destroy!
      end

      private

      attr_reader :state

      def delayed_deletion_active?
        Feature.enabled?(:terraform_state_delayed_deletion, state.project)
      end

      # Overridden in EE
      def process_batch(batch)
        batch.each do |version|
          version.file.remove!
        end
      end
    end
  end
end

Terraform::States::DestroyService.prepend_mod
