# frozen_string_literal: true

module Repositories
  # A finder class for getting the tag of the last release before a given
  # version, used when generating changelogs.
  #
  # Imagine a project with the following tags:
  #
  # * v1.0.0
  # * v1.1.0
  # * v2.0.0
  #
  # If the version supplied is 2.1.0, the tag returned will be v2.0.0. And when
  # the version is 1.1.1, or 1.2.0, the returned tag will be v1.1.0.
  #
  # To obtain the tags, this finder requires a regular expression (using the re2
  # syntax) to be provided. This regex must produce the following named
  # captures:
  #
  # - major (required)
  # - minor (required)
  # - patch (required)
  # - pre
  # - meta
  #
  # If the `pre` group has a value, the tag is ignored. If any of the required
  # capture groups don't have a value, the tag is also ignored.
  class ChangelogTagFinder
    def initialize(project, regex: Gitlab::Changelog::Config::DEFAULT_TAG_REGEX)
      @project = project
      @regex = regex
    end

    def execute(new_version)
      tags = {}

      # Custom regex matcher extracts versions from repository tags
      # This format is defined by the user and applied to repository tags only
      # https://docs.gitlab.com/ee/user/project/changelogs.html#customize-the-tag-format-when-extracting-versions
      custom_regex_matcher = matcher(@regex)

      # Default regex macher extracts the user provided version
      # The regex is different here, because it must match API documentation requirements
      # https://gitlab.com/gitlab-org/gitlab/-/blob/44ab4e5bccdea01642b2f42bcccef706409ebfec/doc/api/repositories.md#L338
      default_regex_matcher = matcher(Gitlab::Changelog::Config::DEFAULT_TAG_REGEX)

      version_components = default_regex_matcher.match(new_version)
      requested_version = assemble_version(version_components)

      unless requested_version
        raise Gitlab::Changelog::Error,
          _("The requested `version` attribute format is not correct. Use formats such as `1.0.0` or `v1.0.0`.")
      end

      versions = [requested_version]

      @project.repository.tags.each do |tag|
        version_components = custom_regex_matcher.match(tag.name)

        next unless version_components

        # When using this class for generating changelog data for a range of
        # commits, we want to compare against the tag of the last _stable_
        # release; not some random RC that came after that
        next if version_components[:pre]

        version = assemble_version(version_components)

        next unless version

        tags[version] = tag
        versions << version
      end

      VersionSorter.sort!(versions)

      index = versions.index(requested_version)

      tags[versions[index - 1]] if index&.positive?
    end

    private

    def matcher(regex)
      Gitlab::UntrustedRegexp.new(regex)
    rescue RegexpError => e
      # The error messages produced by default are not very helpful, so we
      # raise a better one here. We raise the specific error here so its
      # message is displayed in the API (where we catch this specific
      # error).
      raise(
        Gitlab::Changelog::Error,
        "The regular expression to use for finding the previous tag for a version is invalid: #{e.message}"
      )
    end

    # Builds a version string based on regex matcher's output
    def assemble_version(matches)
      return if matches.blank?

      major = matches[:major]
      minor = matches[:minor]
      patch = matches[:patch]
      build = matches[:meta]

      return unless major && minor && patch

      version = "#{major}.#{minor}.#{patch}"
      version += "+#{build}" if build

      version
    end
  end
end
