# frozen_string_literal: true

module Repositories
  module Tags
    class GpgSignature < ApplicationRecord
      include ShaAttribute

      self.table_name = 'tag_gpg_signatures'
      enum :verification_status, Enums::CommitSignature.verification_statuses

      belongs_to :project, optional: false
      belongs_to :gpg_key
      belongs_to :gpg_key_subkey

      sha_attribute :object_name
      sha_attribute :gpg_key_primary_keyid

      validates :object_name, presence: true, uniqueness: { scope: :project_id }
      validates :gpg_key_primary_keyid, presence: true
    end
  end
end
