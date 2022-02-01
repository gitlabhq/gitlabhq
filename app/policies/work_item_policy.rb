# frozen_string_literal: true

class WorkItemPolicy < BasePolicy
  delegate { @subject.project }

  desc 'User is author of the work item'
  condition(:author) do
    @user && @user == @subject.author
  end

  rule { can?(:owner_access) | author }.enable :delete_work_item
end
