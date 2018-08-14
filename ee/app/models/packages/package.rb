# frozen_string_literal: true
class Packages::Package < ActiveRecord::Base
  belongs_to :project
  has_many :package_files
  has_one :maven_metadatum, inverse_of: :package

  accepts_nested_attributes_for :maven_metadatum

  validates :project, presence: true

  validates :name,
    presence: true,
    format: { with: Gitlab::Regex.package_name_regex }
end
