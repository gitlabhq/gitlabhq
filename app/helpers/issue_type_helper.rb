# frozen_string_literal: true

module IssueTypeHelper
  def issue_type_for(issue)
    return if issue.blank?

    if Feature.enabled?(:issue_type_uses_work_item_types_table)
      issue.work_item_type.base_type
    else
      issue.issue_type
    end
  end
end
