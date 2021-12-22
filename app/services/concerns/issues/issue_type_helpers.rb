# frozen_string_literal: true

module Issues
  module IssueTypeHelpers
    # @param object [Issue, Project]
    # @param issue_type [String, Symbol]
    def create_issue_type_allowed?(object, issue_type)
      WorkItems::Type.base_types.key?(issue_type.to_s) &&
        can?(current_user, :"create_#{issue_type}", object)
    end
  end
end
