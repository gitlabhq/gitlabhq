class Packages::PackageFileUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  # TODO: Implement me
end
