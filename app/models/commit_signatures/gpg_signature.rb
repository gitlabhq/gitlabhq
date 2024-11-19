# frozen_string_literal: true
module CommitSignatures
  class GpgSignature < ApplicationRecord
    include CommitSignature
    include SignatureType
    include EachBatch

    sha_attribute :gpg_key_primary_keyid

    belongs_to :gpg_key
    belongs_to :gpg_key_subkey

    validates :gpg_key_primary_keyid, presence: true

    def signed_by_user
      return gpg_key.user if gpg_key

      # system signed gpg keys may not have a gpg key in rails.
      # instead take the user from the gpg signature.
      User.find_by_any_email(gpg_key_user_email) if verified_system? && Feature.enabled?(
        :check_for_mailmapped_commit_emails, project)
    end

    def type
      :gpg
    end

    def self.with_key_and_subkeys(gpg_key)
      subkey_ids = gpg_key.subkeys.pluck(:id)

      where(
        arel_table[:gpg_key_id].eq(gpg_key.id).or(
          arel_table[:gpg_key_subkey_id].in(subkey_ids)
        )
      )
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

    def gpg_key
      if gpg_key_id
        super
      elsif gpg_key_subkey_id
        gpg_key_subkey
      end
    end

    def gpg_key_primary_keyid
      super&.upcase
    end

    def gpg_commit
      return unless commit

      Gitlab::Gpg::Commit.new(commit)
    end

    def user
      gpg_key&.user
    end
  end
end
