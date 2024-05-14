# frozen_string_literal: true

module Gitlab
  module PathTraversal
    extend self
    PathTraversalAttackError = Class.new(StandardError)

    private_class_method def logger
      @logger ||= Gitlab::AppLogger
    end

    PATH_TRAVERSAL_REGEX = %r{\A(\.{1,2})\z|\A\.\.[/\\]|[/\\]\.\.\z|[/\\]\.\.[/\\]}
    PATH_TRAVERSAL_REGEX_WITH_NEWLINE = %r{(#{PATH_TRAVERSAL_REGEX}|\n)}

    # Ensure that the relative path will not traverse outside the base directory
    # We url decode the path to avoid passing invalid paths forward in url encoded format.
    # Also see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24223#note_284122580
    # It also checks for backslash '\', which is sometimes a File::ALT_SEPARATOR.
    def check_path_traversal!(path)
      return unless path

      path = path.to_s if path.is_a?(Gitlab::HashedPath)
      raise PathTraversalAttackError, 'Invalid path' unless path.is_a?(String)

      path = ::Gitlab::Utils.decode_path(path)

      if path_traversal?(path)
        logger.warn(message: "Potential path traversal attempt detected", path: path.to_s)
        raise PathTraversalAttackError, 'Invalid path'
      end

      path
    end

    def path_traversal?(decoded_path, match_new_line: true)
      return false unless decoded_path

      regex = if match_new_line
                PATH_TRAVERSAL_REGEX_WITH_NEWLINE
              else
                PATH_TRAVERSAL_REGEX
              end

      decoded_path.match?(regex)
    end

    def check_allowed_absolute_path!(path, allowlist)
      return unless Pathname.new(path).absolute?
      return if ::Gitlab::Utils.allowlisted?(path, allowlist)

      raise StandardError, "path #{path} is not allowed"
    end

    def check_allowed_absolute_path_and_path_traversal!(path, path_allowlist)
      traversal_path = check_path_traversal!(path)
      raise StandardError, "path is not a string!" unless traversal_path.is_a?(String)

      check_allowed_absolute_path!(traversal_path, path_allowlist)
    end
  end
end
