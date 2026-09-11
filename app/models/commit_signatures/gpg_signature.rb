# frozen_string_literal: true

module CommitSignatures
  class GpgSignature < ApplicationRecord
    extend ::Gitlab::Utils::Override
    include CommitSignature
    include SignatureType
    include EachBatch

    sha_attribute :gpg_key_primary_keyid

    belongs_to :gpg_key
    belongs_to :gpg_key_subkey

    validates :gpg_key_primary_keyid, presence: true

    override :safe_create!
    def self.safe_create!(attributes)
      create_with(attributes)
        .safe_find_or_create_by!( # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- This overrides an existent class method defined in CommitSignature concern
          project_id: attributes[:project].id,
          commit_sha: attributes[:commit_sha]
        )
    end

    def signed_by_user
      gpg_key&.user
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
