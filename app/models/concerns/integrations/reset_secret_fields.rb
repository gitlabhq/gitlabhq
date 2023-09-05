# frozen_string_literal: true

# Integrations should reset their "secret" fields (type: 'password') when certain "exposing"
# fields are changed (e.g. URLs), to avoid leaking secrets to unauthorized parties.
# The result of this is that users have to reenter the secrets to confirm the change.
module Integrations
  module ResetSecretFields
    extend ActiveSupport::Concern

    included do
      before_validation :reset_secret_fields!, if: :reset_secret_fields?
    end

    def exposing_secrets_fields
      fields.select(&:exposes_secrets).pluck(:name)
    end

    private

    def reset_secret_fields?
      exposing_secrets_fields.any? do |field|
        public_send("#{field}_changed?") # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    def reset_secret_fields!
      secret_fields.each do |field|
        next if public_send("#{field}_touched?") # rubocop:disable GitlabSecurity/PublicSend

        public_send("#{field}=", nil) # rubocop:disable GitlabSecurity/PublicSend

        # NOTE: Some of our specs also write to properties in addition to data fields,
        # in order to test backwards compatibility. So in those cases we also need to
        # clear the field in properties, since the setter above will only affect the data field.
        self.properties = properties.except(field) if properties.present?
      end
    end
  end
end
