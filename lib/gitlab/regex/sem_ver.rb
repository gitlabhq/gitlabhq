# frozen_string_literal: true

module Gitlab
  module Regex
    module SemVer
      extend self

      def optional_prefixed
        Regexp.new("\\Av?#{::Gitlab::Regex.unbounded_semver_regex.source}\\z",
          ::Gitlab::Regex.unbounded_semver_regex.options)
      end
    end
  end
end
