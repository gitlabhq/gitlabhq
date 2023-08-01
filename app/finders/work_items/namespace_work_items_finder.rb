# frozen_string_literal: true

module WorkItems
  class NamespaceWorkItemsFinder < WorkItemsFinder
    def execute
      items = init_collection

      sort(items)
    end

    override :with_confidentiality_access_check
    def with_confidentiality_access_check
      return klass.none unless parent && current_user&.can?("read_#{parent.to_ability_name}".to_sym, parent)
      return model_class.all if params.user_can_see_all_issuables?

      # Only admins can see hidden issues, so for non-admins, we filter out any hidden issues
      issues = model_class.without_hidden.in_namespaces(parent)

      return issues.all if params.user_can_see_all_confidential_issues?

      return issues.public_only if params.user_cannot_see_confidential_issues?

      issues.with_confidentiality_check(current_user)
    end
  end
end
