class Email < ActiveRecord::Base
  include Sortable

  belongs_to :user

  validates :user_id, presence: true
  validates :email, presence: true, uniqueness: true, email: true
  validate :unique_email, if: ->(email) { email.email_changed? }

  def email=(value)
    write_attribute(:email, value.downcase.strip)
  end

  def unique_email
    self.errors.add(:email, 'has already been taken') if User.exists?(email: self.email)
  end
end
