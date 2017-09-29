class GpgKeySubkey < ActiveRecord::Base
  include ShaAttribute

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

  def method_missing(m, *a, &b)
    return super unless gpg_key.respond_to?(m)

    gpg_key.public_send(m, *a, &b) # rubocop:disable GitlabSecurity/PublicSend
  end

  def respond_to_missing?(method, include_private = false)
    gpg_key.respond_to?(method, include_private) || super
  end
end
