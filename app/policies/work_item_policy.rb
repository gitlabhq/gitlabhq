# frozen_string_literal: true

class WorkItemPolicy < IssuePolicy
  condition(:is_member) { is_project_member? }
  condition(:is_member_and_author) { is_project_member? & is_author? }

  rule { can?(:admin_issue) }.enable :admin_work_item
  rule { can?(:destroy_issue) | is_member_and_author }.enable :delete_work_item

  rule { can?(:update_issue) }.enable :update_work_item

  rule { can?(:set_issue_metadata) }.enable :set_work_item_metadata

  rule { can?(:read_issue) }.enable :read_work_item
  # because IssuePolicy delegates to ProjectPolicy and
  # :read_work_item is enabled in ProjectPolicy too, we
  # need to make sure we also prevent this rule if read_issue
  # is prevented
  rule { ~can?(:read_issue) }.prevent :read_work_item

  rule { (is_member & can?(:read_work_item)) | admin }.policy do
    enable :admin_work_item_link
    enable :admin_parent_link
  end

  rule { is_incident & ~can?(:reporter_access) }.policy do
    prevent :update_work_item
    prevent :admin_work_item
  end

  rule { is_incident & ~can?(:owner_access) }.policy do
    prevent :delete_work_item
  end

  # IMPORTANT: keep the prevent rules as last rules defined in the policy, as these are based on
  # all abilities defined up to this point.
  rule { group_issue & ~group_level_issues_license_available }.policy do
    prevent(*::WorkItemPolicy.ability_map.map.keys)
  end
end

WorkItemPolicy.prepend_mod
