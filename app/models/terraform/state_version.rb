# frozen_string_literal: true

module Terraform
  class StateVersion < ApplicationRecord
    include EachBatch
    include FileStoreMounter
    include ObjectStorable

    STORE_COLUMN = :file_store

    belongs_to :terraform_state, class_name: 'Terraform::State', optional: false, touch: true
    belongs_to :created_by_user, class_name: 'User', optional: true
    belongs_to :build, class_name: 'Ci::Build', optional: true, foreign_key: :ci_build_id

    scope :ordered_by_version_desc, -> { order(version: :desc) }
    scope :preload_state, -> { includes(:terraform_state) }

    attribute :file_store, default: -> { StateUploader.default_store }

    mount_file_store_uploader StateUploader

    delegate :project_id, :uuid, to: :terraform_state, allow_nil: true

    before_create :set_encrypted_flag

    def encryption_enabled?
      return true unless Feature.enabled?(:skip_encrypting_terraform_state_file, terraform_state.project)
      return true if ApplicationSetting.current&.terraform_state_encryption_enabled.nil?

      ApplicationSetting.current.terraform_state_encryption_enabled
    end

    private

    def set_encrypted_flag
      self.is_encrypted = encryption_enabled?
    end
  end
end

Terraform::StateVersion.prepend_mod_with('Terraform::StateVersion')
