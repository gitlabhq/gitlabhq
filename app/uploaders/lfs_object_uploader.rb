class LfsObjectUploader < ObjectStoreUploader
  storage_options Gitlab.config.lfs
  after :store, :schedule_migration_to_object_storage

  def self.local_store_path
    Gitlab.config.lfs.storage_path
  end

  def filename
    subject.oid[4..-1]
  end

  private

  def default_path
    "#{subject.oid[0, 2]}/#{subject.oid[2, 2]}"
  end
end
