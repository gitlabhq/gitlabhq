# frozen_string_literal: true

class GitalyVersionChecker
  # parse_gitlab_version parses the content of the VERSION
  # file and return the GitLab version
  def parse_gitlab_version(content)
    # Extract only the semver part (MAJOR.MINOR.PATCH)
    # And strip everything else (ex: `-pre` suffix)
    stripped_content = content.strip
    semver = stripped_content[/^(\d+\.\d+\.\d+)/, 1]

    abort "No valid semantic version found in: '#{content}'" unless semver

    Gem::Version.new(semver)
  end

  # parse_gitaly_version parses the content of the
  # Gemfile.lock file and returns the Gitaly version
  # used in the Gemfile.
  def parse_gitaly_version(content)
    # Find the gitaly gem entry in Gemfile.lock
    # Format: "    gitaly (18.8.1)"
    match = content.match(/^\s{4}gitaly \(([^)]+)\)/)

    if match
      Gem::Version.new(match[1])
    else
      abort "Gitaly gem not found in Gemfile.lock"
    end
  rescue ArgumentError => e
    abort "Invalid Gitaly version format: #{e.message}"
  end

  def version_allowed?(gitlab_version, gitaly_version)
    gitlab_segments = gitlab_version.segments
    gitaly_segments = gitaly_version.segments

    gitlab_major = gitlab_segments[0]
    gitlab_minor = gitlab_segments[1]

    gitaly_major = gitaly_segments[0]
    gitaly_minor = gitaly_segments[1]

    # Gitaly must be at least 1 minor version behind GitLab
    # This means Gitaly's minor version must be strictly less than GitLab's minor version
    # (assuming same major version)
    if gitaly_major != gitlab_major
      # Different major versions - Gitaly should not be ahead
      gitaly_major < gitlab_major
    else
      # Same major version - Gitaly minor must be strictly less than GitLab minor
      gitaly_minor < gitlab_minor
    end
  end
end
