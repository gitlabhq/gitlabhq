# frozen_string_literal: true

# This follows the rules specified in the specs.
# See spec/requests/api/graphql/mutations/merge_requests/set_assignees_spec.rb

module Issuable
  class ProcessAssignees
    def initialize(assignee_ids:, add_assignee_ids:, remove_assignee_ids:, existing_assignee_ids: nil, extra_assignee_ids: nil)
      @assignee_ids = assignee_ids
      @add_assignee_ids = add_assignee_ids
      @remove_assignee_ids = remove_assignee_ids
      @existing_assignee_ids = existing_assignee_ids || []
      @extra_assignee_ids = extra_assignee_ids || []
    end

    def execute
      updated_new_assignees = new_assignee_ids

      if add_assignee_ids.blank? && remove_assignee_ids.blank?
        updated_new_assignees = assignee_ids if assignee_ids
      else
        updated_new_assignees |= add_assignee_ids if add_assignee_ids
        updated_new_assignees -= remove_assignee_ids if remove_assignee_ids
      end

      updated_new_assignees.uniq
    end

    private

    attr_accessor :assignee_ids, :add_assignee_ids, :remove_assignee_ids, :existing_assignee_ids, :extra_assignee_ids

    def new_assignee_ids
      existing_assignee_ids | extra_assignee_ids
    end
  end
end
