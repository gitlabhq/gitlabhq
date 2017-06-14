module EE
  module Gitlab
    module Regex
      def variable_scope_regex
        @variable_scope_regex ||= /\A[a-zA-Z0-9_\\\/\${}. -*]+\z/.freeze
      end

      def variable_scope_regex_message
        "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', '*' and spaces"
      end
    end
  end
end
