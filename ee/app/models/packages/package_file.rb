# frozen_string_literal: true
class Packages::PackageFile < ActiveRecord::Base
  belongs_to :package

  validates :package, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  mount_uploader :file, Packages::PackageFileUploader
end
