# frozen_string_literal: true

module Namespaces
  module Stateful
    # Scopes and query methods to resolve namespace state from ancestor hierarchies
    module StateQuerying
      extend ActiveSupport::Concern

      included do
        # Handles both NULL and 0 values for ancestor_inherited during migration.
        # TODO: Simplify to `where.not(state: :deletion_in_progress)` after NULL->0 backfill
        #   https://gitlab.com/gitlab-org/gitlab/-/issues/588431
        scope :not_deletion_in_progress, -> do
          where('state != ? OR state IS NULL', Namespaces::Stateful::STATES[:deletion_in_progress])
        end
      end

      # Returns the effective state for this namespace, considering ancestor inheritance.
      # If the namespace has its own explicit state (not ancestor_inherited), returns that state.
      # Otherwise, traverses up the ancestor hierarchy to find the first ancestor with an explicit state.
      # Returns :ancestor_inherited if no ancestor has an explicit state.
      #
      # @return [Symbol] the effective state name
      def effective_state
        return state_name if !ancestor_inherited? || parent_id.nil?

        # During migration, ancestor_inherited can be either NULL or 0.
        # Exclude both when looking for an ancestor with an explicit state.
        closest_ancestor_state =
          self.class
             .where(id: traversal_ids)
             .where.not(state: STATES[:ancestor_inherited])
             .where.not(state: nil) # TODO: Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/588431
             .order(Arel.sql("array_length(traversal_ids, 1) DESC"))
             .pick(:state)

        return :ancestor_inherited if closest_ancestor_state.nil?

        STATES.key(closest_ancestor_state).to_sym
      end
    end
  end
end
