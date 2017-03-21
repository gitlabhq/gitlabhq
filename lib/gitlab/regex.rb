module Gitlab
  module Regex
    extend self

    # The namespace regex is used in Javascript to validate usernames in the "Register" form. However, Javascript
    # does not support the negative lookbehind assertion (?<!) that disallows usernames ending in `.git` and `.atom`.
    # Since this is a non-trivial problem to solve in Javascript (heavily complicate the regex, modify view code to
    # allow non-regex validatiions, etc), `NAMESPACE_REGEX_STR_JS` serves as a Javascript-compatible version of
    # `NAMESPACE_REGEX_STR`, with the negative lookbehind assertion removed. This means that the client-side validation
    # will pass for usernames ending in `.atom` and `.git`, but will be caught by the server-side validation.
    PATH_REGEX_STR = '[a-zA-Z0-9_\.][a-zA-Z0-9_\-\.]*'.freeze
    NAMESPACE_REGEX_STR_JS = PATH_REGEX_STR + '[a-zA-Z0-9_\-]|[a-zA-Z0-9_]'.freeze
    NO_SUFFIX_REGEX_STR = '(?<!\.git|\.atom)'.freeze
    NAMESPACE_REGEX_STR = "(?:#{NAMESPACE_REGEX_STR_JS})#{NO_SUFFIX_REGEX_STR}".freeze
    PROJECT_REGEX_STR = "(?:#{PATH_REGEX_STR})#{NO_SUFFIX_REGEX_STR}".freeze

    # Same as NAMESPACE_REGEX_STR but allows `/` in the path.
    # So `group/subgroup` will match this regex but not NAMESPACE_REGEX_STR
    FULL_NAMESPACE_REGEX_STR = "(?:#{NAMESPACE_REGEX_STR}/)*#{NAMESPACE_REGEX_STR}".freeze

    def namespace_regex
      @namespace_regex ||= /\A#{NAMESPACE_REGEX_STR}\z/.freeze
    end

    def namespace_route_regex
      @namespace_route_regex ||= /#{NAMESPACE_REGEX_STR}/.freeze
    end

    def namespace_regex_message
      "can contain only letters, digits, '_', '-' and '.'. " \
      "Cannot start with '-' or end in '.', '.git' or '.atom'." \
    end

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

    def project_path_regex
      @project_path_regex ||= /\A#{PROJECT_REGEX_STR}\z/.freeze
    end

    def project_route_regex
      @project_route_regex ||= /#{PROJECT_REGEX_STR}/.freeze
    end

    def project_git_route_regex
      @project_route_git_regex ||= /#{PATH_REGEX_STR}\.git/.freeze
    end

    def project_path_regex_message
      "can contain only letters, digits, '_', '-' and '.'. " \
      "Cannot start with '-', end in '.git' or end in '.atom'" \
    end

    def file_name_regex
      @file_name_regex ||= /\A[[[:alnum:]]_\-\.\@\+]*\z/.freeze
    end

    def file_name_regex_message
      "can contain only letters, digits, '_', '-', '@', '+' and '.'."
    end

    def file_path_regex
      @file_path_regex ||= /\A[[[:alnum:]]_\-\.\/\@]*\z/.freeze
    end

    def file_path_regex_message
      "can contain only letters, digits, '_', '-', '@' and '.'. Separate directories with a '/'."
    end

    def directory_traversal_regex
      @directory_traversal_regex ||= /\.{2}/.freeze
    end

    def directory_traversal_regex_message
      "cannot include directory traversal."
    end

    def archive_formats_regex
      #                           |zip|tar|    tar.gz    |         tar.bz2         |
      @archive_formats_regex ||= /(zip|tar|tar\.gz|tgz|gz|tar\.bz2|tbz|tbz2|tb2|bz2)/.freeze
    end

    def git_reference_regex
      # Valid git ref regex, see:
      # https://www.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html

      @git_reference_regex ||= %r{
        (?!
           (?# doesn't begins with)
           \/|                    (?# rule #6)
           (?# doesn't contain)
           .*(?:
              [\/.]\.|            (?# rule #1,3)
              \/\/|               (?# rule #6)
              @\{|                (?# rule #8)
              \\                  (?# rule #9)
           )
        )
        [^\000-\040\177~^:?*\[]+  (?# rule #4-5)
        (?# doesn't end with)
        (?<!\.lock)               (?# rule #1)
        (?<![\/.])                (?# rule #6-7)
      }x.freeze
    end

    def container_registry_reference_regex
      git_reference_regex
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
