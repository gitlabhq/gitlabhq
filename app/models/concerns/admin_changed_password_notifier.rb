# frozen_string_literal: true

module AdminChangedPasswordNotifier
  # This module is responsible for triggering the `Password changed by administrator` emails
  # when a GitLab administrator changes the password of another user.

  # Usage
  # These emails are disabled by default and are never trigerred after updating the password, unless
  # explicitly specified.

  # To explicitly trigger this email, the `send_only_admin_changed_your_password_notification!`
  # method should be called, so like:

  # user = User.find_by(email: 'hello@example.com')
  # user.send_only_admin_changed_your_password_notification!
  # user.password = user.password_confirmation = 'new_password'
  # user.save!

  # The `send_only_admin_changed_your_password_notification` has 2 responsibilities.
  # It prevents triggering Devise's default `Password changed` email.
  # It trigggers the `Password changed by administrator` email.

  # It is important to skip sending the default Devise email when sending out `Password changed by administrator`
  # email because we should not be sending 2 emails for the same event,
  # hence the only public API made available from this module is `send_only_admin_changed_your_password_notification!`

  # There is no public API made available to send the `Password changed by administrator` email,
  # *without* skipping the default `Password changed` email, to prevent the problem mentioned above.

  extend ActiveSupport::Concern

  included do
    # default value of this attribute is `nil`, so these emails are off by default
    attr_accessor :allow_admin_changed_your_password_notification

    after_update :send_admin_changed_your_password_notification, if: :send_admin_changed_your_password_notification?
  end

  def send_only_admin_changed_your_password_notification!
    skip_password_change_notification! # skip sending the default Devise 'password changed' notification
    allow_admin_changed_your_password_notification!
  end

  private

  def send_admin_changed_your_password_notification
    send_devise_notification(:password_change_by_admin)
  end

  def allow_admin_changed_your_password_notification!
    self.allow_admin_changed_your_password_notification = true
  end

  def send_admin_changed_your_password_notification?
    self.class.send_password_change_notification && saved_change_to_encrypted_password? &&
      allow_admin_changed_your_password_notification
  end
end
