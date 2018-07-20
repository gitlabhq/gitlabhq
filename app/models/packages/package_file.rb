class Packages::PackageFile < ActiveRecord::Base
  belongs_to :package

  mount_uploader :file, PackageFileUploader
end
