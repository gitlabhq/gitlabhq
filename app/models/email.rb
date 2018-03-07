class Email < ActiveRecord::Base
  include Sortable
  include Gitlab::SQL::Pattern

  belongs_to :user

  validates :user_id, presence: true
  validates :email, presence: true, uniqueness: true, email: true
  validate :unique_email, if: ->(email) { email.email_changed? }

  scope :confirmed, -> { where.not(confirmed_at: nil) }

  after_commit :update_invalid_gpg_signatures, if: -> { previous_changes.key?('confirmed_at') }

  devise :confirmable
  self.reconfirmable = false  # currently email can't be changed, no need to reconfirm

  delegate :username, to: :user

  def email=(value)
    write_attribute(:email, value.downcase.strip)
  end

  def unique_email
    self.errors.add(:email, 'has already been taken') if User.exists?(email: self.email)
  end

  # once email is confirmed, update the gpg signatures
  def update_invalid_gpg_signatures
    user.update_invalid_gpg_signatures if confirmed?
  end
end
