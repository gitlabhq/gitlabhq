# frozen_string_literal: true

module Users
  class UpdateCanonicalEmailService
    extend ActiveSupport::Concern

    INCLUDED_DOMAINS_PATTERN = [/gmail.com/].freeze

    def initialize(user:)
      raise ArgumentError, "Please provide a user" unless user.is_a?(User)

      @user = user
    end

    def execute
      return unless user.email
      return unless user.email.match? Devise.email_regexp

      canonical_email = ::Gitlab::Utils::Email.normalize_email(user.email)

      unless Regexp.union(INCLUDED_DOMAINS_PATTERN).match?(canonical_email)
        # the canonical email doesn't exist, probably because the domain doesn't match
        # destroy any UserCanonicalEmail record associated with this user
        user.user_canonical_email&.delete
        # nothing else to do here
        return
      end

      if user.user_canonical_email
        # update to the new value
        user.user_canonical_email.canonical_email = canonical_email
      else
        user.build_user_canonical_email(canonical_email: canonical_email)
      end
    end

    private

    attr_reader :user
  end
end
