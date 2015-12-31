class GitHook < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true, unless: "is_sample?"

  def commit_validation?
    commit_message_regex.present? ||
      author_email_regex.present? ||
      member_check ||
      file_name_regex.present? ||
      max_file_size > 0
  end

  def commit_message_allowed?(message)
    data_valid?(message, commit_message_regex)
  end

  def author_email_allowed?(email)
    data_valid?(email, author_email_regex)
  end

  private

  def data_valid?(data, regex)
    if regex.present?
      !!(data =~ Regexp.new(regex))
    else
      true
    end
  end
end
