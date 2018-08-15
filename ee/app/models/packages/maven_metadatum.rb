# frozen_string_literal: true
class Packages::MavenMetadatum < ActiveRecord::Base
  belongs_to :package

  validates :package, presence: true

  validates :path,
    presence: true,
    format: { with: Gitlab::Regex.maven_path_regex }

  validates :app_group,
    presence: true,
    format: { with: Gitlab::Regex.maven_app_group_regex }

  validates :app_name,
    presence: true,
    format: { with: Gitlab::Regex.maven_app_name_regex }
end
