# frozen_string_literal: true

module Namespaces
  module Stateful
    # Scopes and query methods to resolve namespace state from ancestor hierarchies
    module StateQuerying
      extend ActiveSupport::Concern

      included do
        scope :with_deletion_scheduled_by_user, -> { includes(namespace_details: :deletion_scheduled_by_user) }

        scope :deletion_scheduled_before, ->(time) do
          joins(:namespace_details)
            .merge(Namespace::Detail.deletion_scheduled_before(time))
        end

        delegate :deletion_scheduled_by_user, to: :namespace_details
      end

      # Returns the effective state for this namespace, considering ancestor inheritance.
      # If the namespace has its own explicit state (not ancestor_inherited), returns that state.
      # Otherwise, traverses up the ancestor hierarchy to find the first ancestor with an explicit state.
      # Returns :ancestor_inherited if no ancestor has an explicit state.
      #
      # @return [Symbol] the effective state name
      def effective_state
        return state_name if !ancestor_inherited? || parent_id.nil?

        closest_ancestor_state =
          self.class
             .where(id: traversal_ids)
             .where.not(state: :ancestor_inherited)
             .order(Arel.sql("array_length(traversal_ids, 1) DESC"))
             .pick(:state)

        return :ancestor_inherited if closest_ancestor_state.nil?

        closest_ancestor_state.to_sym
      end
    end
  end
end
