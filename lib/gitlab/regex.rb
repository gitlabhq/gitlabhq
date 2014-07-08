module Gitlab
  module Regex
    extend self

    def username_regex
      default_regex
    end

    def username_regex_message
      default_regex_message
    end

    def project_name_regex
      /\A[a-zA-Z0-9_][a-zA-Z0-9_\-\. ]*\z/
    end

    def project_regex_message
      "can contain only letters, digits, '_', '-' and '.' and space. " \
      "It must start with letter, digit or '_'."
    end

    def name_regex
      /\A[a-zA-Z0-9_\-\. ]*\z/
    end

    def name_regex_message
      "can contain only letters, digits, '_', '-' and '.' and space."
    end

    def path_regex
      default_regex
    end

    def path_regex_message
      default_regex_message
    end

    def archive_formats_regex
      #|zip|tar|    tar.gz    |         tar.bz2         |
      /(zip|tar|tar\.gz|tgz|gz|tar\.bz2|tbz|tbz2|tb2|bz2)/
    end

    def git_reference_regex
      # Valid git ref regex, see:
      # https://www.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html

      %r{
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
      }x
    end

    protected

    def default_regex_message
      "can contain only letters, digits, '_', '-' and '.'. " \
      "It must start with letter, digit or '_', optionally preceeded by '.'. " \
      "It must not end in '.git'."
    end

    def default_regex
      /\A[a-zA-Z0-9_.][a-zA-Z0-9_\-\.]*(?<!\.git)\z/
    end
  end
end
