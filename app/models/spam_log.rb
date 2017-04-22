class SpamLog < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true

  def remove_user(deleted_by:)
    user.block
    DeleteUserWorker.perform_async(deleted_by.id, user.id, delete_solo_owned_groups: true, hard_delete: true)
  end

  def text
    [title, description].join("\n")
  end
end
