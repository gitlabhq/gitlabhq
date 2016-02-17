module Gitlab
  module Regex
    extend self

    NAMESPACE_REGEX_STR = '(?:[a-zA-Z0-9_\.][a-zA-Z0-9_\-\.]*[a-zA-Z0-9_\-]|[a-zA-Z0-9_])'.freeze

    def namespace_regex
      @namespace_regex ||= /\A#{NAMESPACE_REGEX_STR}\z/.freeze
    end

    def namespace_regex_message
      "can contain only letters, digits, '_', '-' and '.'. " \
      "Cannot start with '-' or end in '.'." \
    end


    def namespace_name_regex
      @namespace_name_regex ||= /\A[\p{Alnum}\p{Pd}_\. ]*\z/.freeze
    end

    def namespace_name_regex_message
      "can contain only letters, digits, '_', '.', dash and space."
    end


    def project_name_regex
      @project_name_regex ||= /\A[\p{Alnum}_][\p{Alnum}\p{Pd}_\. ]*\z/.freeze
    end

    def project_name_regex_message
      "can contain only letters, digits, '_', '.', dash and space. " \
      "It must start with letter, digit or '_'."
    end


    def project_path_regex
      @project_path_regex ||= /\A[a-zA-Z0-9_.][a-zA-Z0-9_\-\.]*(?<!\.git|\.atom)\z/.freeze
    end

    def project_path_regex_message
      "can contain only letters, digits, '_', '-' and '.'. " \
      "Cannot start with '-', end in '.git' or end in '.atom'" \
    end


    def file_name_regex
      @file_name_regex ||= /\A[a-zA-Z0-9_\-\.\@]*\z/.freeze
    end

    def file_name_regex_message
      "can contain only letters, digits, '_', '-', '@' and '.'. "
    end

    def file_path_regex
      @file_path_regex ||= /\A[a-zA-Z0-9_\-\.\/\@]*\z/.freeze
    end

    def file_path_regex_message
      "can contain only letters, digits, '_', '-', '@' and '.'. Separate directories with a '/'. "
    end


    def directory_traversal_regex
      @directory_traversal_regex ||= /\.{2}/.freeze
    end

    def directory_traversal_regex_message
      "cannot include directory traversal. "
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
  end
end
