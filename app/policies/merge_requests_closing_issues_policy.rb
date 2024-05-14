# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass -- Model and policy will be renamed
# TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/456869
class MergeRequestsClosingIssuesPolicy < BasePolicy
  condition(:can_read_issue) { can?(:read_issue, @subject.issue) }

  condition(:can_read_merge_request) { can?(:read_merge_request, @subject.merge_request) }

  rule { can_read_issue & can_read_merge_request }.policy do
    enable :read_merge_request_closing_issue
  end
end
# rubocop:enable Gitlab/NamespacedClass
