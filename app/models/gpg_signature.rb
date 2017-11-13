class GpgSignature < ActiveRecord::Base
  include ShaAttribute

  sha_attribute :commit_sha
  sha_attribute :gpg_key_primary_keyid

  enum verification_status: {
    unverified: 0,
    verified: 1,
    same_user_different_email: 2,
    other_user: 3,
    unverified_key: 4,
    unknown_key: 5
  }

  belongs_to :project
  belongs_to :gpg_key
  belongs_to :gpg_key_subkey

  validates :commit_sha, presence: true
  validates :project_id, presence: true
  validates :gpg_key_primary_keyid, presence: true

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

  def commit
    project.commit(commit_sha)
  end

  def gpg_commit
    return unless commit

    Gitlab::Gpg::Commit.new(commit)
  end
end
