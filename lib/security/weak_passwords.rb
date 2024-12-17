# frozen_string_literal: true
module Security
  module WeakPasswords
    # These words are predictable in GitLab's specific context, and
    # therefore cannot occur anywhere within a password.
    FORBIDDEN_WORDS = Set['gitlab', 'devops'].freeze

    # Substrings shorter than this may appear legitimately in a truly
    # random password.
    MINIMUM_SUBSTRING_SIZE = 4

    # Passwords of 64+ characters are more likely to randomly include a
    # forbidden substring.
    #
    # This length was chosen somewhat arbitrarily, balancing security,
    # usability, and skipping checks on `::User.random_password` which
    # is 128 chars. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105755
    PASSWORD_SUBSTRING_CHECK_MAX_LENGTH = 64

    class << self
      # Returns true when the password is on a list of weak passwords,
      # or contains predictable substrings derived from user attributes.
      # Case insensitive.
      def weak_for_user?(password, user)
        user_info_in_password?(password, user) || common_phrases_in_password?(password)
      end

      def user_info_in_password?(password, user)
        name_appears_in_password?(password, user) ||
          username_appears_in_password?(password, user) ||
          email_appears_in_password?(password, user)
      end

      def common_phrases_in_password?(password)
        forbidden_word_appears_in_password?(password) || password_on_weak_list?(password)
      end

      private

      def forbidden_word_appears_in_password?(password)
        contains_predicatable_substring?(password, FORBIDDEN_WORDS)
      end

      def name_appears_in_password?(password, user)
        return false if user.name.blank?

        # Check for the full name
        substrings = [user.name]
        # Also check parts of their name
        substrings += user.name.split(/[^\p{Alnum}]/)

        contains_predicatable_substring?(password, substrings)
      end

      def username_appears_in_password?(password, user)
        return false if user.username.blank?

        # Check for the full username
        substrings = [user.username]
        # Also check sub-strings in the username
        substrings += user.username.split(/[^\p{Alnum}]/)

        contains_predicatable_substring?(password, substrings)
      end

      def email_appears_in_password?(password, user)
        return false if user.email.blank?

        # Check for the full email
        substrings = [user.email]
        # Also check full first part and full domain name
        substrings += user.email.split("@")
        # And any parts of non-word characters (e.g. firstname.lastname+tag@...)
        substrings += user.email.split(/[^\p{Alnum}]/)

        contains_predicatable_substring?(password, substrings)
      end

      def password_on_weak_list?(password)
        # Our weak list stores SHA2 hashes of passwords, not the weak
        # passwords themselves.
        digest = Digest::SHA256.base64digest(password.downcase)
        Settings.gitlab.weak_passwords_digest_set.include?(digest)
      end

      # Case-insensitively checks whether a password includes a dynamic
      # list of substrings. Substrings which are too short are not
      # predictable and may occur randomly, and therefore not checked.
      # Similarly passwords which are long enough to inadvertently and
      # randomly include a substring are not checked.
      def contains_predicatable_substring?(password, substrings)
        return unless password.length < PASSWORD_SUBSTRING_CHECK_MAX_LENGTH

        substrings = substrings.filter_map do |substring|
          substring.downcase if substring.length >= MINIMUM_SUBSTRING_SIZE
        end

        password = password.downcase

        # Returns true when a predictable substring occurs anywhere
        # in the password.
        substrings.any? { |word| password.include?(word) }
      end
    end
  end
end
