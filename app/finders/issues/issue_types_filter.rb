# frozen_string_literal: true

module Issues # rubocop:disable Gitlab/BoundedContexts -- existing Finders modules/classes are not bounded
  class IssueTypesFilter < Issuables::BaseFilter
    def filter(issues)
      by_issue_types(issues)
    end

    private

    def by_issue_types(issues)
      return issues if param_types.blank?
      return issues.model.none unless valid_param_types?

      issues.with_issue_type(param_types)
    end

    def valid_param_types?
      (::WorkItems::Type.base_types.keys & param_types).sort == param_types.sort
    end

    def param_types
      Array.wrap(params[:issue_types]).map(&:to_s)
    end
  end
end # rubocop:enable Gitlab/BoundedContexts

Issues::IssueTypesFilter.prepend_mod
