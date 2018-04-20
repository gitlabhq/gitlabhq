module Geo
  class HashedStorageMigratedEvent < ActiveRecord::Base
    include Geo::Model
    include IgnorableColumn

    ignore_column :repository_storage_path

    belongs_to :project

    validates :project, :repository_storage_name,
              :old_disk_path, :new_disk_path, :old_wiki_disk_path,
              :new_wiki_disk_path, :new_storage_version, presence: true
  end
end
