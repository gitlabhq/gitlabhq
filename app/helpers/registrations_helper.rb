# frozen_string_literal: true

module RegistrationsHelper
  def signup_username_data_attributes
    {
      min_length: User::MIN_USERNAME_LENGTH,
      min_length_message: s_('SignUp|Username is too short (minimum is %{min_length} characters).') % {
        min_length: User::MIN_USERNAME_LENGTH
      },
      max_length: User::MAX_USERNAME_LENGTH,
      max_length_message: s_('SignUp|Username is too long (maximum is %{max_length} characters).') % {
        max_length: User::MAX_USERNAME_LENGTH
      },
      testid: 'new-user-username-field'
    }
  end
end

RegistrationsHelper.prepend_mod_with('RegistrationsHelper')
