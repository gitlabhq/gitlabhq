# frozen_string_literal: true

module Repositories
  # A finder class for getting the tag of the last release before a given
  # version.
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
  # This finder expects that all tags to consider meet the following
  # requirements:
  #
  # * They start with the letter "v" followed by a version, or immediately start
  #   with a version
  # * They use semantic versioning for the version format
  #
  # Tags not meeting these requirements are ignored.
  class PreviousTagFinder
    TAG_REGEX = /\Av?(?<version>#{Gitlab::Regex.unbounded_semver_regex})\z/.freeze

    def initialize(project)
      @project = project
    end

    def execute(new_version)
      tags = {}
      versions = [new_version]

      @project.repository.tags.each do |tag|
        matches = tag.name.match(TAG_REGEX)

        next unless matches

        # When using this class for generating changelog data for a range of
        # commits, we want to compare against the tag of the last _stable_
        # release; not some random RC that came after that.
        next if matches[:prerelease]

        version = matches[:version]
        tags[version] = tag
        versions << version
      end

      VersionSorter.sort!(versions)

      index = versions.index(new_version)

      tags[versions[index - 1]] if index&.positive?
    end
  end
end
