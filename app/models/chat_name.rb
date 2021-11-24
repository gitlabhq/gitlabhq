# frozen_string_literal: true

class ChatName < ApplicationRecord
  LAST_USED_AT_INTERVAL = 1.hour

  belongs_to :integration, foreign_key: :service_id
  belongs_to :user

  validates :user, presence: true
  validates :integration, presence: true
  validates :team_id, presence: true
  validates :chat_id, presence: true

  validates :user_id, uniqueness: { scope: [:service_id] }
  validates :chat_id, uniqueness: { scope: [:service_id, :team_id] }

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
    last_used_at.nil? || last_used_at > LAST_USED_AT_INTERVAL.ago
  end
end
