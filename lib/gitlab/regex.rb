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

    def file_name_regex
      @file_name_regex ||= /\A[[[:alnum:]]_\-\.\@\+]*\z/.freeze
    end

    def file_name_regex_message
      "can contain only letters, digits, '_', '-', '@', '+' and '.'."
    end

    def container_registry_reference_regex
      Gitlab::PathRegex.git_reference_regex
    end

    ##
    # Docker Distribution Registry 2.4.1 repository name rules
    #
    def container_repository_name_regex
      @container_repository_regex ||= %r{\A[a-z0-9]+(?:[-._/][a-z0-9]+)*\Z}
    end

    def environment_name_regex
      @environment_name_regex ||= /\A[a-zA-Z0-9_\\\/\${}. -]+\z/.freeze
    end

    def environment_name_regex_message
      "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.' and spaces"
    end

    def kubernetes_namespace_regex
      /\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/
    end

    def kubernetes_namespace_regex_message
      "can contain only letters, digits or '-', and cannot start or end with '-'"
    end

    def environment_slug_regex
      @environment_slug_regex ||= /\A[a-z]([a-z0-9-]*[a-z0-9])?\z/.freeze
    end

    def environment_slug_regex_message
      "can contain only lowercase letters, digits, and '-'. " \
      "Must start with a letter, and cannot end with '-'"
    end
  end
end
