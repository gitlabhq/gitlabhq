# frozen_string_literal: true

module Terraform
  class State < ApplicationRecord
    belongs_to :project

    validates :project_id, presence: true

    after_save :update_file_store, if: :saved_change_to_file?

    mount_uploader :file, StateUploader

    def update_file_store
      # The file.object_store is set during `uploader.store!`
      # which happens after object is inserted/updated
      self.update_column(:file_store, file.object_store)
    end

    def file_store
      super || StateUploader.default_store
    end
  end
end
