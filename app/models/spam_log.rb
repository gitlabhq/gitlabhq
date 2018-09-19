# frozen_string_literal: true

class SpamLog < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true

  def remove_user(deleted_by:)
    user.delete_async(deleted_by: deleted_by, params: { hard_delete: true })
  end

  def text
    [title, description].join("\n")
  end
end
