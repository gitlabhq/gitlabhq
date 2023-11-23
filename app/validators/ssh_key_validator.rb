# frozen_string_literal: true

# SshKeyValidator
#
# Custom validator for SSH keys.
#
#   class Project < ActiveRecord::Base
#     validates :key, ssh_key: true
#   end
#
class SshKeyValidator < ActiveModel::EachValidator # rubocop:disable Gitlab/NamespacedClass -- Allow setting ssh_key by convention
  def validate_each(record, attribute, value)
    public_key = Gitlab::SSHPublicKey.new(value)

    restriction = Gitlab::CurrentSettings.key_restriction_for(public_key.type)

    if restriction == ApplicationSetting::FORBIDDEN_KEY_VALUE
      record.errors.add(attribute, forbidden_key_type_message)
    elsif public_key.bits < restriction
      record.errors.add(attribute, "must be at least #{restriction} bits")
    end
  end

  private

  def forbidden_key_type_message
    allowed_types = Gitlab::CurrentSettings.allowed_key_types.map(&:upcase)

    "type is forbidden. Must be #{Gitlab::Sentence.to_exclusive_sentence(allowed_types)}"
  end
end
