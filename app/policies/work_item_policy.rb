# frozen_string_literal: true

class WorkItemPolicy < IssuePolicy
  rule { can?(:owner_access) | is_author }.enable :delete_work_item

  rule { can?(:update_issue) }.enable :update_work_item

  rule { can?(:read_issue) }.enable :read_work_item
end
