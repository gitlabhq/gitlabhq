# frozen_string_literal: true

class SpamLog < ApplicationRecord
  belongs_to :user

  validates :user, presence: true

  def remove_user(deleted_by:)
    user.delete_async(deleted_by: deleted_by, params: { hard_delete: true })
  end

  def text
    [title, description].join("\n")
  end

  def self.verify_recaptcha!(id:, user_id:)
    find_by(id: id, user_id: user_id)&.update!(recaptcha_verified: true)
  end
end
