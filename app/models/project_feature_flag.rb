class ProjectFeatureFlag < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true
  validates :name,
    presence: true,
    length: 2..63,
    format: {
      with: Gitlab::Regex.feature_flag_regex,
      message: Gitlab::Regex.feature_flag_regex_message
    }
end
