# frozen_string_literal: true

module IssueLinks
  class ListService < IssuableLinks::ListService
    extend ::Gitlab::Utils::Override

    private

    def child_issuables
      issuable.related_issues(current_user, preload: preload_for_collection)
    end

    override :serializer
    def serializer
      LinkedProjectIssueSerializer
    end
  end
end
