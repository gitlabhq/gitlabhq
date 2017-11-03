# == DeviseConfirmable concern
#
# Overrides Devise::Models::Confirmable
#
module DeviseConfirmable
  extend ActiveSupport::Concern

  # Users and Emails can contain unconfirmed duplicates.  When one is confirmed,
  # remove any duplicates (don't remove duplicate User emails, just leave unconfirmed)
  def confirm(args={})
    saved = false
    if !Email.confirmed.exists?(email: email) && !User.confirmed.exists?(email: email)
      if saved = super
        # remove any duplicate emails from the emails table
        Email.unconfirmed.where(email: email).destroy_all

        # nothing to do about the duplicate user emails, just leave unconfirmed
      end
    else
      self.errors.add(:base, 'This email address was confirmed to belong to another account')
    end
    saved
  end
end
