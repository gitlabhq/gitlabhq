# frozen_string_literal: true

class ChatName < ApplicationRecord
  include Gitlab::EncryptedAttribute

  LAST_USED_AT_INTERVAL = 1.hour
  MAX_PARAM_LENGTH = 8192

  belongs_to :user

  validates :user, presence: true
  validates :team_id, presence: true, length: { maximum: MAX_PARAM_LENGTH }
  validates :team_domain, length: { maximum: MAX_PARAM_LENGTH }
  validates :chat_id, presence: true, length: { maximum: MAX_PARAM_LENGTH }
  validates :chat_name, length: { maximum: MAX_PARAM_LENGTH }

  validates :chat_id, uniqueness: { scope: :team_id }
  validates :token, length: { maximum: MAX_PARAM_LENGTH }

  attr_encrypted :token,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key: :db_key_base_32,
    encode: false,
    encode_iv: false

  # Updates the "last_used_timestamp" but only if it wasn't already updated
  # recently.
  #
  # The throttling this method uses is put in place to ensure that high chat
  # traffic doesn't result in many UPDATE queries being performed.
  def update_last_used_at
    return unless update_last_used_at?

    obtained = Gitlab::ExclusiveLease
      .new("chat_name/last_used_at/#{id}", timeout: LAST_USED_AT_INTERVAL.to_i)
      .try_obtain

    touch(:last_used_at) if obtained
  end

  def update_last_used_at?
    last_used_at.nil? || last_used_at.before?(LAST_USED_AT_INTERVAL.ago)
  end
end
