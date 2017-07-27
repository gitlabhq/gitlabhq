module EE
  module Gitlab
    module Regex
      def environment_scope_regex_chars
        "#{environment_name_regex_chars}\\*"
      end

      def environment_scope_regex
        @environment_scope_regex ||= /\A[#{environment_scope_regex_chars}]+\z/.freeze
      end

      def environment_scope_regex_message
        "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', '*' and spaces"
      end
    end
  end
end
