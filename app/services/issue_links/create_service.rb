# frozen_string_literal: true

module IssueLinks
  class CreateService < IssuableLinks::CreateService
    extend ::Gitlab::Utils::Override
    include IncidentManagement::UsageData
    include Gitlab::Utils::StrongMemoize

    def success(...)
      GraphqlTriggers.work_item_updated(issuable)
      super
    end

    override :linkable_issuables
    def linkable_issuables
      referenced_issuables.select { |issue| can?(current_user, :admin_issue_link, issue) }
    end
    strong_memoize_attr :linkable_issuables

    override :previous_related_issuables
    def previous_related_issuables
      issuable.related_issues(authorize: false).to_a
    end
    strong_memoize_attr :previous_related_issuables

    private

    override :readonly_issuables
    def readonly_issuables
      referenced_issuables.select { |issuable| issuable.readable_by?(current_user) }
    end
    strong_memoize_attr :readonly_issuables

    def track_event
      track_incident_action(current_user, issuable, :incident_relate)
    end

    def link_class
      IssueLink
    end

    def extractor_context
      issuable.group_level? ? { group: issuable.namespace } : {}
    end
  end
end

IssueLinks::CreateService.prepend_mod
