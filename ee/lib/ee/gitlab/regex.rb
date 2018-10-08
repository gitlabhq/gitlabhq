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

      def package_name_regex
        @package_name_regex ||= %r{\A(([\w\-\.]*)/)*([\w\-\.]*)\z}.freeze
      end

      def maven_path_regex
        package_name_regex
      end

      def maven_app_name_regex
        @maven_app_name_regex ||= /\A[\w\-\.]+\z/.freeze
      end

      def maven_app_group_regex
        maven_app_name_regex
      end

      def feature_flag_regex
        /\A[a-z]([-_a-z0-9]*[a-z0-9])?\z/
      end

      def feature_flag_regex_message
        "can contain only lowercase letters, digits, '_' and '-'. " \
        "Must start with a letter, and cannot end with '-' or '_'"
      end
    end
  end
end
