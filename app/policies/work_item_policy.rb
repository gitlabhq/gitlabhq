# frozen_string_literal: true

class WorkItemPolicy < IssuePolicy
  condition(:is_member_and_author) { is_project_member? & is_author? }

  rule { can?(:destroy_issue) | is_member_and_author }.enable :delete_work_item

  rule { can?(:update_issue) }.enable :update_work_item

  rule { can?(:read_issue) }.enable :read_work_item
  # because IssuePolicy delegates to ProjectPolicy and
  # :read_work_item is enabled in ProjectPolicy too, we
  # need to make sure we also prevent this rule if read_issue
  # is prevented
  rule { ~can?(:read_issue) }.prevent :read_work_item

  rule { can?(:reporter_access) }.policy do
    enable :admin_parent_link
  end
end
