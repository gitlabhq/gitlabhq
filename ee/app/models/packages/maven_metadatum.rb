# frozen_string_literal: true
class Packages::MavenMetadatum < ActiveRecord::Base
  belongs_to :package

  validates :package, presence: true
  validates :path, presence: true
  validates :app_group, presence: true
  validates :app_name, presence: true
end
