module EE
  module Gitlab
    module Regex
      def variable_scope_regex_chars
        "#{environment_name_regex_chars}\\*"
      end

      def variable_scope_regex
        @variable_scope_regex ||= /\A[#{variable_scope_regex_chars}]+\z/.freeze
      end

      def variable_scope_regex_message
        "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', '*' and spaces"
      end
    end
  end
end
