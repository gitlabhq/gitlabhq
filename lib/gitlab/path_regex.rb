module Gitlab
  module PathRegex
    extend self

    # All routes that appear on the top level must be listed here.
    # This will make sure that groups cannot be created with these names
    # as these routes would be masked by the paths already in place.
    #
    # Example:
    #   /api/api-project
    #
    #  the path `api` shouldn't be allowed because it would be masked by `api/*`
    #
    TOP_LEVEL_ROUTES = %w[
      -
      .well-known
      404.html
      422.html
      500.html
      502.html
      503.html
      abuse_reports
      admin
      api
      apple-touch-icon-precomposed.png
      apple-touch-icon.png
      assets
      autocomplete
      ci
      dashboard
      deploy.html
      explore
      favicon.ico
      files
      groups
      header_logo_dark.png
      header_logo_light.png
      health_check
      help
      import
      invites
      jwt
      koding
      notification_settings
      oauth
      profile
      projects
      public
      robots.txt
      s
      search
      sent_notifications
      slash-command-logo.png
      snippets
      u
      unsubscribes
      uploads
      users
    ].freeze

    # This list should contain all words following `/*namespace_id/:project_id` in
    # routes that contain a second wildcard.
    #
    # Example:
    #   /*namespace_id/:project_id/badges/*ref/build
    #
    # If `badges` was allowed as a project/group name, we would not be able to access the
    # `badges` route for those projects:
    #
    # Consider a namespace with path `foo/bar` and a project called `badges`.
    # The route to the build badge would then be `/foo/bar/badges/badges/master/build.svg`
    #
    # When accessing this path the route would be matched to the `badges` path
    # with the following params:
    #   - namespace_id: `foo`
    #   - project_id: `bar`
    #   - ref: `badges/master`
    #
    # Failing to find the project, this would result in a 404.
    #
    # By rejecting `badges` the router can _count_ on the fact that `badges` will
    # be preceded by the `namespace/project`.
    PROJECT_WILDCARD_ROUTES = %w[
      -
      badges
      blame
      blob
      builds
      commits
      create
      create_dir
      edit
      environments/folders
      files
      find_file
      gitlab-lfs/objects
      info/lfs/objects
      new
      preview
      raw
      refs
      tree
      update
      wikis
    ].freeze

    # These are all the paths that follow `/groups/*id/ or `/groups/*group_id`
    # We need to reject these because we have a `/groups/*id` page that is the same
    # as the `/*id`.
    #
    # If we would allow a subgroup to be created with the name `activity` then
    # this group would not be accessible through `/groups/parent/activity` since
    # this would map to the activity-page of its parent.
    GROUP_ROUTES = %w[
      -
    ].freeze

    ILLEGAL_PROJECT_PATH_WORDS = PROJECT_WILDCARD_ROUTES
    ILLEGAL_GROUP_PATH_WORDS = (PROJECT_WILDCARD_ROUTES | GROUP_ROUTES).freeze

    # The namespace regex is used in JavaScript to validate usernames in the "Register" form. However, Javascript
    # does not support the negative lookbehind assertion (?<!) that disallows usernames ending in `.git` and `.atom`.
    # Since this is a non-trivial problem to solve in Javascript (heavily complicate the regex, modify view code to
    # allow non-regex validations, etc), `NAMESPACE_FORMAT_REGEX_JS` serves as a Javascript-compatible version of
    # `NAMESPACE_FORMAT_REGEX`, with the negative lookbehind assertion removed. This means that the client-side validation
    # will pass for usernames ending in `.atom` and `.git`, but will be caught by the server-side validation.
    PATH_REGEX_STR = '[a-zA-Z0-9_\.][a-zA-Z0-9_\-\.]*'.freeze
    NAMESPACE_FORMAT_REGEX_JS = PATH_REGEX_STR + '[a-zA-Z0-9_\-]|[a-zA-Z0-9_]'.freeze

    NO_SUFFIX_REGEX = /(?<!\.git|\.atom)/.freeze
    NAMESPACE_FORMAT_REGEX = /(?:#{NAMESPACE_FORMAT_REGEX_JS})#{NO_SUFFIX_REGEX}/.freeze
    PROJECT_PATH_FORMAT_REGEX = /(?:#{PATH_REGEX_STR})#{NO_SUFFIX_REGEX}/.freeze
    FULL_NAMESPACE_FORMAT_REGEX = %r{(#{NAMESPACE_FORMAT_REGEX}/)*#{NAMESPACE_FORMAT_REGEX}}.freeze

    def root_namespace_route_regex
      @root_namespace_route_regex ||= begin
        illegal_words = Regexp.new(Regexp.union(TOP_LEVEL_ROUTES).source, Regexp::IGNORECASE)

        single_line_regexp %r{
          (?!(#{illegal_words})/)
          #{NAMESPACE_FORMAT_REGEX}
        }x
      end
    end

    def full_namespace_route_regex
      @full_namespace_route_regex ||= begin
        illegal_words = Regexp.new(Regexp.union(ILLEGAL_GROUP_PATH_WORDS).source, Regexp::IGNORECASE)

        single_line_regexp %r{
          #{root_namespace_route_regex}
          (?:
            /
            (?!#{illegal_words}/)
            #{NAMESPACE_FORMAT_REGEX}
          )*
        }x
      end
    end

    def project_route_regex
      @project_route_regex ||= begin
        illegal_words = Regexp.new(Regexp.union(ILLEGAL_PROJECT_PATH_WORDS).source, Regexp::IGNORECASE)

        single_line_regexp %r{
          (?!(#{illegal_words})/)
          #{PROJECT_PATH_FORMAT_REGEX}
        }x
      end
    end

    def project_git_route_regex
      @project_git_route_regex ||= /#{project_route_regex}\.git/.freeze
    end

    def full_namespace_path_regex
      @full_namespace_path_regex ||= %r{\A#{full_namespace_route_regex}/\z}
    end

    def full_project_path_regex
      @full_project_path_regex ||= %r{\A#{full_namespace_route_regex}/#{project_route_regex}/\z}
    end

    def full_project_git_path_regex
      @full_project_git_path_regex ||= %r{\A\/?(?<namespace_path>#{full_namespace_route_regex})\/(?<project_path>#{project_route_regex})\.git\z}
    end

    def namespace_format_regex
      @namespace_format_regex ||= /\A#{NAMESPACE_FORMAT_REGEX}\z/.freeze
    end

    def namespace_format_message
      "can contain only letters, digits, '_', '-' and '.'. " \
      "Cannot start with '-' or end in '.', '.git' or '.atom'." \
    end

    def project_path_format_regex
      @project_path_format_regex ||= /\A#{PROJECT_PATH_FORMAT_REGEX}\z/.freeze
    end

    def project_path_format_message
      "can contain only letters, digits, '_', '-' and '.'. " \
      "Cannot start with '-', end in '.git' or end in '.atom'" \
    end

    def archive_formats_regex
      #                           |zip|tar|    tar.gz    |         tar.bz2         |
      @archive_formats_regex ||= /(zip|tar|tar\.gz|tgz|gz|tar\.bz2|tbz|tbz2|tb2|bz2)/.freeze
    end

    def git_reference_regex
      # Valid git ref regex, see:
      # https://www.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html

      @git_reference_regex ||= single_line_regexp %r{
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

    private

    def single_line_regexp(regex)
      # Turns a multiline extended regexp into a single line one,
      # beacuse `rake routes` breaks on multiline regexes.
      Regexp.new(regex.source.gsub(/\(\?#.+?\)/, '').gsub(/\s*/, ''), regex.options ^ Regexp::EXTENDED).freeze
    end
  end
end
