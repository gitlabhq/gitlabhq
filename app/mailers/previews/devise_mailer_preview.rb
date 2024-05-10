# frozen_string_literal: true

class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions_for_signup
    DeviseMailer.confirmation_instructions(unsaved_user, 'faketoken', {})
  end

  def confirmation_instructions_for_new_email
    user = User.last
    user.unconfirmed_email = 'unconfirmed@example.com'

    DeviseMailer.confirmation_instructions(user, 'faketoken', {})
  end

  def confirmation_instructions_for_secondary_email
    user = User.last
    secondary_email = user.emails.build(email: 'unconfirmed@example.com')

    DeviseMailer.confirmation_instructions(secondary_email, 'faketoken', {})
  end

  def reset_password_instructions
    DeviseMailer.reset_password_instructions(unsaved_user, 'faketoken', {})
  end

  def unlock_instructions
    DeviseMailer.unlock_instructions(unsaved_user, 'faketoken', {})
  end

  def password_change
    DeviseMailer.password_change(unsaved_user, {})
  end

  def user_admin_approval
    DeviseMailer.user_admin_approval(unsaved_user, {})
  end

  def email_changed
    DeviseMailer.email_changed(unsaved_user, {})
  end

  private

  def unsaved_user
    User.new(name: 'Jane Doe', email: 'jdoe@example.com', created_at: 1.minute.ago)
  end
end
