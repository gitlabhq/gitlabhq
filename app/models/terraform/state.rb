# frozen_string_literal: true

module Terraform
  class State < ApplicationRecord
    include UsageStatistics

    DEFAULT = '{"version":1}'.freeze
    HEX_REGEXP = %r{\A\h+\z}.freeze
    UUID_LENGTH = 32

    belongs_to :project
    belongs_to :locked_by_user, class_name: 'User'

    validates :project_id, presence: true
    validates :uuid, presence: true, uniqueness: true, length: { is: UUID_LENGTH },
              format: { with: HEX_REGEXP, message: 'only allows hex characters' }

    default_value_for(:uuid, allows_nil: false) { SecureRandom.hex(UUID_LENGTH / 2) }

    after_save :update_file_store, if: :saved_change_to_file?

    mount_uploader :file, StateUploader

    default_value_for(:file) { CarrierWaveStringFile.new(DEFAULT) }

    def update_file_store
      # The file.object_store is set during `uploader.store!`
      # which happens after object is inserted/updated
      self.update_column(:file_store, file.object_store)
    end

    def file_store
      super || StateUploader.default_store
    end

    def locked?
      self.lock_xid.present?
    end
  end
end
