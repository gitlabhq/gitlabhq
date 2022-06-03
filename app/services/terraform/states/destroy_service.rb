# frozen_string_literal: true

module Terraform
  module States
    class DestroyService
      def initialize(state)
        @state = state
      end

      def execute
        return unless state.deleted_at?

        state.versions.each_batch(column: :version) do |batch|
          batch.each do |version|
            version.file.remove!
          end
        end

        state.destroy!
      end

      private

      attr_reader :state
    end
  end
end
