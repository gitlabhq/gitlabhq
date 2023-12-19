# frozen_string_literal: true

module WorkItems
  class NamespaceWorkItemsFinder < WorkItemsFinder
    FilterNotAvailableError = Class.new(ArgumentError)

    def initialize(...)
      super

      self.parent_param = namespace
    end

    override :with_confidentiality_access_check
    def with_confidentiality_access_check
      return model_class.all if params.user_can_see_all_issuables?

      # Only admins can see hidden issues, so for non-admins, we filter out any hidden issues
      issues = model_class.without_hidden

      return issues.all if params.user_can_see_all_confidential_issues?

      return issues.public_only if params.user_cannot_see_confidential_issues?

      issues.with_confidentiality_check(current_user)
    end

    private

    def filter_items(items)
      items = super(items)

      by_namespace(items)
    end

    def by_namespace(items)
      if namespace.blank? || !Ability.allowed?(current_user, "read_#{namespace.to_ability_name}".to_sym, namespace)
        return klass.none
      end

      items.in_namespaces(namespace)
    end

    override :by_search
    def by_search(items)
      return items unless search

      raise FilterNotAvailableError, 'Searching is not available for work items at the namespace level yet'
    end

    def namespace
      return if params[:namespace_id].blank?

      params[:namespace_id].is_a?(Namespace) ? params[:namespace_id] : Namespace.find_by_id(params[:namespace_id])
    end
    strong_memoize_attr :namespace

    override :by_parent
    def by_parent(items)
      items
    end
  end
end
