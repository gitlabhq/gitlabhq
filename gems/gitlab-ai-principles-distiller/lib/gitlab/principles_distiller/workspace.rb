# frozen_string_literal: true

require 'rainbow'

require_relative 'env'

module Gitlab
  module PrinciplesDistiller
    # Process-wide pointer to the repository workspace. Set via
    # `Workspace.path = ...` (typically by the bin scripts honoring
    # `--workspace`), or falls back to `$CI_PROJECT_DIR`.
    module Workspace
      PathTraversalError = Class.new(StandardError)

      # Mirrors the regex used by `Gitlab::PathTraversal` in the host
      # GitLab app (`lib/gitlab/path_traversal.rb`) so behaviour stays
      # consistent across codebases.
      PATH_TRAVERSAL_REGEX = %r{\A(\.{1,2})\z|\A\.\.[/\\]|[/\\]\.\.\z|[/\\]\.\.[/\\]}

      class << self
        attr_writer :path

        def path
          @path || ENV.fetch(Env::CI_PROJECT_DIR) do
            abort Rainbow('ERROR: workspace path not set. Pass --workspace, set CI_PROJECT_DIR, ' \
              'or call Gitlab::PrinciplesDistiller::Workspace.path = ...').red
          end
        end

        # Joins the workspace root with the given segments after rejecting
        # any segment that contains a `..` traversal. Use for every path
        # opened off the workspace, including paths derived from manifest
        # YAML or other user-controlled input.
        def safe_join(*segments)
          segments.each { |segment| check_path_traversal!(segment) }

          File.join(path, *segments)
        end

        # Raises if `segment` contains a `..` path-traversal sequence.
        # Treats backslash as an alternative separator (some platforms use
        # `\` as `File::ALT_SEPARATOR`).
        def check_path_traversal!(segment)
          return if segment.nil?

          raise PathTraversalError, 'Invalid path' unless segment.is_a?(String)
          return unless segment.match?(PATH_TRAVERSAL_REGEX)

          raise PathTraversalError, "Path traversal detected: #{segment.inspect}"
        end
      end
    end
  end
end
