# frozen_string_literal: true

module ObjectStorable
  extend ActiveSupport::Concern

  included do
    scope :with_files_stored_locally, -> { where(klass::STORE_COLUMN => ObjectStorage::Store::LOCAL) }
    scope :with_files_stored_remotely, -> { where(klass::STORE_COLUMN => ObjectStorage::Store::REMOTE) }
  end
end
