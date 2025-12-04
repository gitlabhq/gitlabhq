# frozen_string_literal: true

class GpgKeySubkey < ApplicationRecord
  include ShaAttribute
  include Cells::Claimable

  cells_claims_attribute :fingerprint, type: CLAIMS_BUCKET_TYPE::GPG_SUBKEY_FINGERPRINTS
  cells_claims_attribute :keyid, type: CLAIMS_BUCKET_TYPE::GPG_SUBKEY_KEYIDS

  cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::GPG_KEY, subject_key: :gpg_key_id

  sha_attribute :keyid
  sha_attribute :fingerprint

  belongs_to :gpg_key

  validates :gpg_key_id, presence: true
  validates :fingerprint, :keyid, presence: true, uniqueness: true

  delegate :key, :user, :user_infos, :verified?, :verified_user_infos,
    :verified_and_belongs_to_email?, to: :gpg_key

  def keyid
    super&.upcase
  end

  def fingerprint
    super&.upcase
  end
end
