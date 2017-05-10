class IssueAssignee < ActiveRecord::Base
  extend Gitlab::CurrentSettings

  belongs_to :issue
  belongs_to :assignee, class_name: "User", foreign_key: :user_id
end
