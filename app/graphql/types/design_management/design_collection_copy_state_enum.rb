# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignCollectionCopyStateEnum < BaseEnum
      graphql_name 'DesignCollectionCopyState'
      description 'Copy state of a DesignCollection'

      DESCRIPTION_VARIANTS = {
        in_progress: 'is being copied',
        error: 'encountered an error during a copy',
        ready: 'has no copy in progress'
      }.freeze

      def self.description_variant(copy_state)
        DESCRIPTION_VARIANTS[copy_state.to_sym] ||
          (raise ArgumentError, "Unknown copy state: #{copy_state}")
      end

      ::DesignManagement::DesignCollection.state_machines[:copy_state].states.keys.each do |copy_state|
        value copy_state.upcase,
          value: copy_state.to_s,
          description: "The DesignCollection #{description_variant(copy_state)}"
      end
    end
  end
end
