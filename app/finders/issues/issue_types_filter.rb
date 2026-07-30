# frozen_string_literal: true

module Issues # rubocop:disable Gitlab/BoundedContexts -- existing Finders modules/classes are not bounded
  class IssueTypesFilter < Issuables::BaseFilter
    def filter(issues)
      issues = by_work_item_type_ids(issues)
      issues = by_work_item_type_names(issues)
      by_issue_types(issues)
    end

    private

    def by_issue_types(issues)
      return issues if param_types.blank?
      return issues.model.none unless valid_param_types?

      issues.with_issue_type(param_types)
    end

    def by_work_item_type_ids(issues)
      filter_by_authorized_type_ids(issues, work_item_type_ids)
    end

    def by_work_item_type_names(issues)
      return issues if work_item_type_names.blank?

      ids = ::WorkItems::TypesFramework::Provider.new(parent).persistable_ids_by_names(work_item_type_names)
      return issues.model.none if ids.empty?

      filter_by_authorized_type_ids(issues, ids)
    end

    # Applies a work item type id filter. Both the id and name filters funnel through here so that
    # EE can enforce type authorization (e.g. stripping the epic type when epics are unavailable)
    # regardless of whether the caller supplied ids or names. See EE::Issues::IssueTypesFilter.
    def filter_by_authorized_type_ids(issues, ids)
      return issues if ids.blank?

      issues.with_work_item_type_ids(ids)
    end

    def valid_param_types?
      (::WorkItems::TypesFramework::Provider.unfiltered_base_types & param_types).sort == param_types.sort
    end

    def param_types
      Array.wrap(params[:issue_types]).map(&:to_s)
    end

    def work_item_type_ids
      Array.wrap(params[:work_item_type_ids]).compact
    end

    def work_item_type_names
      Array.wrap(params[:work_item_type_names])
    end
  end
end # rubocop:enable Gitlab/BoundedContexts

Issues::IssueTypesFilter.prepend_mod
