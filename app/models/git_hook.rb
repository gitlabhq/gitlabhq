class GitHook < ActiveRecord::Base
  attr_accessible :deny_delete_tag, :delete_branch_regex, :commit_message_regex, :force_push_regex

  belongs_to :project
  validates :project, presence: true
end
