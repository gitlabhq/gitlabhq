class PushRule < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true, unless: "is_sample?"
  validates :max_file_size, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  FILES_BLACKLIST = YAML.load_file(Rails.root.join('lib/gitlab/checks/files_blacklist.yml'))
  SETTINGS_WITH_GLOBAL_DEFAULT = %i[
    reject_unsigned_commits
    commit_author_check
  ].freeze

  SETTINGS_WITH_GLOBAL_DEFAULT.each do |setting|
    define_method(setting) do
      value = super()

      # return if value is true/false or if current object is the global setting
      return value if global? || !value.nil?

      PushRule.global&.public_send(setting)
    end
    alias_method "#{setting}?", setting

    define_method("#{setting}=") do |value|
      enabled_globally = PushRule.global&.public_send(setting)
      is_disabled = !Gitlab::Utils.to_boolean(value)

      # If setting is globally disabled and user disable it at project level,
      # reset the attr so we can use the default global if required later.
      if !enabled_globally && is_disabled
        super(nil)
      else
        super(value)
      end
    end
  end

  def self.global
    find_by(is_sample: true)
  end

  def commit_validation?
    commit_message_regex.present? ||
      branch_name_regex.present? ||
      author_email_regex.present? ||
      reject_unsigned_commits ||
      commit_author_check ||
      member_check ||
      file_name_regex.present? ||
      max_file_size > 0 ||
      prevent_secrets
  end

  def commit_signature_allowed?(commit)
    return true unless available?(:reject_unsigned_commits)
    return true unless reject_unsigned_commits

    commit.has_signature?
  end

  def author_allowed?(committer_email, current_user_email)
    return true unless available?(:commit_author_check)
    return true unless commit_author_check

    committer_email.casecmp(current_user_email) == 0
  end

  def commit_message_allowed?(message)
    data_match?(message, commit_message_regex)
  end

  def branch_name_allowed?(branch)
    data_match?(branch, branch_name_regex)
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

  def global?
    is_sample?
  end

  def available?(feature_sym)
    if global?
      License.feature_available?(feature_sym)
    else
      project&.feature_available?(feature_sym)
    end
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
