class PushRule < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true, unless: "is_sample?"
  validates :max_file_size, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  FILES_BLACKLIST = YAML.load_file(Rails.root.join('lib/gitlab/checks/files_blacklist.yml'))

  def commit_validation?
    commit_message_regex.present? ||
      author_email_regex.present? ||
      member_check ||
      file_name_regex.present? ||
      max_file_size > 0 ||
      prevent_secrets
  end

  def commit_message_allowed?(message)
    data_match?(message, commit_message_regex)
  end

  def author_email_allowed?(email)
    data_match?(email, author_email_regex)
  end

  def filename_blacklisted?(file_path)
    regex_list = []
    regex_list.concat(FILES_BLACKLIST) if prevent_secrets
    regex_list << file_name_regex if file_name_regex

    regex_list.find { |regex| data_match?(file_path, regex) }
  end

  private

  def data_match?(data, regex)
    if regex.present?
      !!(data =~ Regexp.new(regex))
    else
      true
    end
  end
end
