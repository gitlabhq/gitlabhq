# frozen_string_literal: true

module Gitlab
  module Slug
    class Path
      LEADING_DASHES = /\A-+/
      # Eextract local email part if given an email. Will remove @ sign and everything following it.
      EXTRACT_LOCAL_EMAIL_PART = /@.*\z/
      FORBIDDEN_CHARACTERS = /[^a-zA-Z0-9_\-.]/
      PATH_TRAILING_VIOLATIONS = %w[.git .atom .].freeze
      DEFAULT_SLUG = 'blank'

      def initialize(input)
        @input = input.dup.to_s
      end

      def generate
        slug = input.gsub(EXTRACT_LOCAL_EMAIL_PART, "")
        slug = slug.gsub(FORBIDDEN_CHARACTERS, "")

        # Remove trailing violations ('.atom', '.git', or '.')
        loop do
          orig = slug
          PATH_TRAILING_VIOLATIONS.each { |extension| slug = slug.chomp extension }
          break if orig == slug
        end
        slug = slug.sub(LEADING_DASHES, "")

        # If all characters were of forbidden nature and filtered out we use this
        # fallback to avoid empty paths
        slug = DEFAULT_SLUG if slug.blank?

        slug
      end

      alias_method :to_s, :generate

      private

      attr_reader :input
    end
  end
end
