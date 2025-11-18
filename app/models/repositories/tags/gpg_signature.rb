# frozen_string_literal: true

module Repositories
  module Tags
    class GpgSignature < ApplicationRecord
      include ShaAttribute
      include SignatureType
      include BulkInsertSafe

      self.table_name = 'tag_gpg_signatures'
      enum :verification_status, Enums::CommitSignature.verification_statuses

      belongs_to :project, optional: false
      belongs_to :gpg_key
      belongs_to :gpg_key_subkey

      sha_attribute :object_name
      sha_attribute :gpg_key_primary_keyid

      validates :object_name, presence: true, uniqueness: { scope: :project_id }
      validates :gpg_key_primary_keyid, presence: true

      scope :by_project, ->(project) { where(project:) }
      scope :by_object_name, ->(object_name) { where(object_name:) }

      def type
        :gpg
      end

      def gpg_key
        if gpg_key_id
          super
        elsif gpg_key_subkey_id
          gpg_key_subkey
        end
      end

      def gpg_key=(model)
        case model
        when GpgKey
          super
        when GpgKeySubkey
          self.gpg_key_subkey = model
        when NilClass
          super
          self.gpg_key_subkey = nil
        end
      end
    end
  end
end
