class SpamLog < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true

  def remove_user
    user.block
    user.destroy
  end
end
