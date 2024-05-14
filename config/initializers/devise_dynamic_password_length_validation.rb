# frozen_string_literal: true

# Discard the default Devise length validation from the `User` model.

# This needs to be discarded because the length validation provided by Devise does not
# support dynamically checking for min and max lengths.

# A new length validation has been added to the User model instead, to keep supporting
# dynamic password length validations, like:

# validates :password, length: { maximum: proc { password_length.max }, minimum: proc { password_length.min } }, allow_blank: true

def length_validator_supports_dynamic_length_checks?(validator)
  validator.options[:minimum].is_a?(Proc) &&
    validator.options[:maximum].is_a?(Proc)
end

# Get the in-built Devise validator on password length.
password_length_validator = User.validators_on(:password).find do |validator|
  validator.kind == :length
end

# This initializer can be removed as soon as https://github.com/plataformatec/devise/pull/5166
# is merged into Devise.

# TODO: Update Devise. Issue: https://gitlab.com/gitlab-org/gitlab/issues/118450
if length_validator_supports_dynamic_length_checks?(password_length_validator)
  raise "Devise now supports dynamic length checks, please remove the monkey patch in #{__FILE__}"
else
  # discard the in-built length validator by always returning true
  def password_length_validator.validate(*_)
    true
  end

  # add a custom password length validator with support for dynamic length validation.
  User.class_eval do
    validates :password, length: { maximum: proc { password_length.max }, minimum: proc { password_length.min } }, allow_blank: true
  end
end
