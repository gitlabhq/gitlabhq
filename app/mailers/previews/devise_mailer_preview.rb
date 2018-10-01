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

  def reset_password_instructions
    DeviseMailer.reset_password_instructions(unsaved_user, 'faketoken', {})
  end

  def unlock_instructions
    DeviseMailer.unlock_instructions(unsaved_user, 'faketoken', {})
  end

  def password_change
    DeviseMailer.password_change(unsaved_user, {})
  end

  private

  def unsaved_user
    User.new(name: 'Jane Doe', email: 'jdoe@example.com')
  end
end
