class GitHook < ActiveRecord::Base
  attr_accessible :deny_delete_tag, :delete_branch_regex, :commit_message_regex, :force_push_regex

  belongs_to :project
  validates :project, presence: true

  def commit_message_allowed?(message)
    if commit_message_regex.present?
      if message =~ Regexp.new(commit_message_regex)
        true
      else
        false
      end
    else
      true
    end
  end
end
