# frozen_string_literal: true
class Packages::PackageFileUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  storage_options Gitlab.config.packages

  after :store, :schedule_background_upload

  alias_method :upload, :model

  def filename
    model.file_name
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              'packages', model.package.id.to_s, 'files', model.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(model.package.project_id.to_s)
  end
end
