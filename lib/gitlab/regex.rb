module Gitlab
  module Regex
    extend self

    def namespace_name_regex
      @namespace_name_regex ||= /\A[\p{Alnum}\p{Pd}_\. ]*\z/.freeze
    end

    def namespace_name_regex_message
      "can contain only letters, digits, '_', '.', dash and space."
    end

    def project_name_regex
      @project_name_regex ||= /\A[\p{Alnum}\u{00A9}-\u{1f9c0}_][\p{Alnum}\p{Pd}\u{00A9}-\u{1f9c0}_\. ]*\z/.freeze
    end

    def project_name_regex_message
      "can contain only letters, digits, emojis, '_', '.', dash, space. " \
      "It must start with letter, digit, emoji or '_'."
    end

    ##
    # Docker Distribution Registry repository / tag name rules
    #
    # See https://github.com/docker/distribution/blob/master/reference/regexp.go.
    #
    def container_repository_name_regex
      @container_repository_regex ||= %r{\A[a-z0-9]+((?:[._/]|__|[-])[a-z0-9]+)*\Z}
    end

    ##
    # We do not use regexp anchors here because these are not allowed when
    # used as a routing constraint.
    #
    def container_registry_tag_regex
      @container_registry_tag_regex ||= /[\w][\w.-]{0,127}/
    end

    def environment_name_regex_chars
      'a-zA-Z0-9_/\\$\\{\\}\\. \\-'
    end

    def environment_name_regex_chars_without_slash
      'a-zA-Z0-9_\\$\\{\\}\\. -'
    end

    def environment_name_regex
      @environment_name_regex ||= /\A[#{environment_name_regex_chars_without_slash}]([#{environment_name_regex_chars}]*[#{environment_name_regex_chars_without_slash}])?\z/.freeze
    end

    def environment_name_regex_message
      "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', and spaces, but it cannot start or end with '/'"
    end

    def kubernetes_namespace_regex
      /\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/
    end

    def kubernetes_namespace_regex_message
      "can contain only lowercase letters, digits, and '-'. " \
      "Must start with a letter, and cannot end with '-'"
    end

    def environment_slug_regex
      @environment_slug_regex ||= /\A[a-z]([a-z0-9-]*[a-z0-9])?\z/.freeze
    end

    def environment_slug_regex_message
      "can contain only lowercase letters, digits, and '-'. " \
      "Must start with a letter, and cannot end with '-'"
    end

    def build_trace_section_regex
      @build_trace_section_regexp ||= /section_((?:start)|(?:end)):(\d+):([a-zA-Z0-9_.-]+)\r\033\[0K/.freeze
    end
  end
end
