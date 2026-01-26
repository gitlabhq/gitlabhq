# frozen_string_literal: true

module Issues
  module IssueTypeHelpers
    # @param object [Issue, Project, Group]
    # @param issue_type [String, Symbol]
    def create_issue_type_allowed?(object, issue_type)
      # TODO: Extract the namespace out of the object and pass it to the provider. Object can be many things.
      # See https://gitlab.com/groups/gitlab-org/-/work_items/20287

      ::WorkItems::TypesFramework::Provider.new(object).type_exists?(issue_type) &&
        can?(current_user, :"create_#{issue_type}", object)
    end
  end
end
