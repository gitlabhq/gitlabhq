# frozen_string_literal: true

module WorkItems
  module SavedViews
    class FilterBaseService < BaseService
      attr_reader :filters, :container, :current_user

      # Filters with values which don't need to be validated on load or save. The values are validated on the GQL layer
      # Overridden in EE
      def self.static_filters
        %i[
          state confidential subscribed issue_types in search my_reaction_emoji closed_before closed_after
          assignee_wildcard_id milestone_wildcard_id release_tag_wildcard_id iid due_before due_after created_before
          created_after updated_before updated_after exclude_projects exclude_group_work_items include_descendants
          include_descendant_work_items
        ]
      end

      def self.static_negated_filters
        %i[milestone_wildcard_id my_reaction_emoji issue_types]
      end
    end
  end
end

WorkItems::SavedViews::FilterBaseService.prepend_mod
