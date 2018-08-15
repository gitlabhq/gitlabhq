# frozen_string_literal: true
class Packages::PackageFile < ActiveRecord::Base
  belongs_to :package

  validates :package, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  mount_uploader :file, Packages::PackageFileUploader

  after_save :update_file_store, if: :file_changed?

  def update_file_store
    # The file.object_store is set during `uploader.store!`
    # which happens after object is inserted/updated
    self.update_column(:file_store, file.object_store)
  end
end
