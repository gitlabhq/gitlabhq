# frozen_string_literal: true

# Shared path normalization utilities for coverage scripts.
#
# Paths from different sources may have different formats:
# - Absolute paths from Coverband: /builds/gitlab-org/gitlab/app/models/user.rb
# - Relative paths with ./ prefix: ./app/models/user.rb
# - Clean relative paths: app/models/user.rb
#
# This module normalizes all paths to clean relative format: app/models/user.rb
module PathNormalizer
  # Known directories with instrumented code at the GitLab project root
  PROJECT_ROOT_DIRS = %w[
    app lib spec ee qa config db scripts tooling vendor
    gems doc workhorse .gitlab locale danger
  ].freeze

  # Matches absolute paths containing /gitlab/ when followed by known project root directories.
  # Uses lookahead to ensure we're matching the repo root, not a subdirectory named 'gitlab'.
  # Optionally matches ./ between /gitlab/ and the project root directory.
  # Examples:
  #   /builds/gitlab-org/gitlab/app/models/user.rb -> app/models/user.rb
  #   /builds/gitlab-org/gitlab/lib/gitlab/api.rb -> lib/gitlab/api.rb (preserves lib/gitlab/)
  #   /builds/gitlab-org/gitlab/./app/models/user.rb -> app/models/user.rb
  GITLAB_ROOT_PATTERN = %r{^.+?/gitlab/(?:\./)?(?=(?:#{PROJECT_ROOT_DIRS.join('|')})/)}

  # Matches ./ prefix at start of path
  RELATIVE_PREFIX_PATTERN = %r{^\./}

  class << self
    # Normalizes a file path to a clean relative path.
    #
    # @param path [String] The file path to normalize
    # @return [String] The normalized path
    def normalize(path)
      return path if path.nil? || path.empty?

      path
        .sub(GITLAB_ROOT_PATTERN, '')
        .sub(RELATIVE_PREFIX_PATTERN, '')
    end
  end
end
