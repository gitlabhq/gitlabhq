# frozen_string_literal: true

module Terraform
  class State < ApplicationRecord
    include UsageStatistics
    include FileStoreMounter
    include IgnorableColumns
    # These columns are being removed since geo replication falls to the versioned state
    # Tracking in https://gitlab.com/gitlab-org/gitlab/-/issues/258262
    ignore_columns %i[verification_failure verification_retry_at verified_at verification_retry_count verification_checksum],
                   remove_with: '13.7',
                   remove_after: '2020-12-22'

    HEX_REGEXP = %r{\A\h+\z}.freeze
    UUID_LENGTH = 32

    belongs_to :project
    belongs_to :locked_by_user, class_name: 'User'

    has_many :versions, class_name: 'Terraform::StateVersion', foreign_key: :terraform_state_id
    has_one :latest_version, -> { ordered_by_version_desc }, class_name: 'Terraform::StateVersion', foreign_key: :terraform_state_id

    scope :versioning_not_enabled, -> { where(versioning_enabled: false) }
    scope :ordered_by_name, -> { order(:name) }

    validates :project_id, presence: true
    validates :uuid, presence: true, uniqueness: true, length: { is: UUID_LENGTH },
              format: { with: HEX_REGEXP, message: 'only allows hex characters' }

    default_value_for(:uuid, allows_nil: false) { SecureRandom.hex(UUID_LENGTH / 2) }
    default_value_for(:versioning_enabled, true)

    mount_file_store_uploader StateUploader

    def file_store
      super || StateUploader.default_store
    end

    def latest_file
      versioning_enabled ? latest_version&.file : file
    end

    def locked?
      self.lock_xid.present?
    end

    def update_file!(data, version:)
      if versioning_enabled?
        new_version = versions.build(version: version)
        new_version.assign_attributes(created_by_user: locked_by_user, file: data)
        new_version.save!
      else
        self.file = data
        save!
      end
    end
  end
end
