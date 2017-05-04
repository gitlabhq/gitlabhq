class IssueAssignee < ActiveRecord::Base
  extend Gitlab::CurrentSettings

  belongs_to :issue
  belongs_to :assignee, class_name: "User", foreign_key: :user_id

  after_create :update_assignee_cache_counts
  after_destroy :update_assignee_cache_counts

  def update_assignee_cache_counts
    assignee&.update_cache_counts
  end
end
