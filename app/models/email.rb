# Secondary emails can be added as long as there is not another
# confirmed email address (either in users or emails tables).
# This prevents someone from camping out on an email address that
# is not their own.  The first email to be confirmed wins.
class Email < ActiveRecord::Base
  include Sortable

  belongs_to :user

  validates :user_id, presence: true
  validates :email, presence: true, email: true
  validates_uniqueness_of :email, scope: :user_id
  validates_uniqueness_of :email, conditions: -> { where.not(confirmed_at: nil) }
  validate :unique_email

  scope :confirmed,   -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  after_commit :update_invalid_gpg_signatures, if: -> { previous_changes.key?('confirmed_at') }

  devise :confirmable
  self.reconfirmable = false  # currently email can't be changed, no need to reconfirm
  include DeviseConfirmable

  delegate :username, to: :user

  def email=(value)
    write_attribute(:email, value.downcase.strip)
  end

  # once email is confirmed, update the gpg signatures
  def update_invalid_gpg_signatures
    user.update_invalid_gpg_signatures if confirmed?
  end

  private

  # check that another user does not have the same confirmed email
  def unique_email
    if User.where.not(confirmed_at: nil).exists?(email: self.email)
      self.errors.add(:email, 'has already been taken')
    end
  end

end
