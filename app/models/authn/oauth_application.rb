# frozen_string_literal: true

module Authn
  class OauthApplication < Doorkeeper::Application
    include Doorkeeper::Concerns::TokenFallback

    belongs_to :organization, class_name: 'Organizations::Organization'

    scope :with_token_digests, ->(hashed_tokens) do
      return none if hashed_tokens.blank?

      where(secret: hashed_tokens)
    end

    # We explicitly disable device_code_enabled here because it's enabled
    # by default in db/migrate/20260224050659_add_device_code_enabled_to_oauth_applications.rb
    # which is so existing records have the option enabled but all new
    # applications should have device_code_enabled set to false.
    attribute :device_code_enabled, default: -> { false }

    # Hashes raw token
    def self.encode(raw_token_value)
      ::Gitlab::DoorkeeperSecretStoring::Sha512Hash.transform_secret(raw_token_value)
    end

    # Check whether the given plain text secret matches our stored secret
    #
    # @param input [#to_s] Plain secret provided by user
    #        (any object that responds to `#to_s`)
    #
    # @return [Boolean] Whether the given secret matches the stored secret
    #                of this application.
    #
    def secret_matches?(input)
      # return false if either is nil, since secure_compare depends on strings
      # but Application secrets MAY be nil depending on confidentiality.
      return false if input.nil? || secret.nil?

      # When matching the secret by comparer function, all is well.
      return true if secret_strategy.secret_matches?(input, secret)

      self.class.fallback_strategies.each do |fallback_strategy|
        # When fallback lookup is enabled, ensure applications
        # with plain secrets can still be found
        return true if fallback_strategy.secret_matches?(input, secret)
      end
      false
    end
  end
end
