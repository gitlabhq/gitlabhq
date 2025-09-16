# frozen_string_literal: true

module Authn
  class OauthApplication < Doorkeeper::Application
    include Doorkeeper::Concerns::TokenFallback

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
