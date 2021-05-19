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

      canonical_email = canonicalize_email

      unless canonical_email
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

    def canonicalize_email
      email = user.email

      portions = email.split('@')
      username = portions.shift
      rest = portions.join

      regex = Regexp.union(INCLUDED_DOMAINS_PATTERN)
      return unless regex.match?(rest)

      no_dots = username.tr('.', '')
      before_plus = no_dots.split('+')[0]
      "#{before_plus}@#{rest}"
    end
  end
end
