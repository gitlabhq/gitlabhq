# frozen_string_literal: true

module Issues
  module IssueTypeHelpers
    # @param object [Issue, Project, Group]
    # @param issue_type [String, Symbol]
    def create_issue_type_allowed?(object, issue_type)
      ::WorkItems::TypesFramework::Provider.new(extract_namespace(object)).type_exists?(issue_type) &&
        can?(current_user, :"create_#{issue_type}", object)
    end

    def extract_namespace(object)
      case object
      when Group, Project
        object
      when Issue
        object.namespace
      end
    end
  end
end
