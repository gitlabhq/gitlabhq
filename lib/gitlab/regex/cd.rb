# frozen_string_literal: true

module Gitlab
  module Regex
    module Cd
      def cd_name_regex
        @cd_name_regex ||= /\A[a-zA-Z0-9_]([a-zA-Z0-9_-]*[a-zA-Z0-9_])?\z/
      end

      def cd_name_regex_message
        "can contain only letters, digits, '_' and '-'. Cannot start or end with '-'."
      end

      def cd_version_name_regex
        @cd_version_name_regex ||= /\A[a-zA-Z0-9_]([a-zA-Z0-9_.-]*[a-zA-Z0-9_])?\z/
      end

      def cd_version_name_regex_message
        "can contain only letters, digits, '_', '.' and '-'. Cannot start or end with '-' or '.'."
      end

      def cd_version_set_name_regex
        @cd_version_set_name_regex ||= Gitlab::Regex::SemVer.optional_prefixed
      end

      def cd_version_set_name_regex_message
        'should follow SemVer, with an optional leading v (for example, 1.2.3 or v1.2.3-rc.1): https://semver.org'
      end
    end
  end
end
