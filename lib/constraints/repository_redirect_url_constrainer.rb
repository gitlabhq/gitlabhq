# frozen_string_literal: true

module Constraints
  class RepositoryRedirectUrlConstrainer
    def matches?(request)
      path = request.params[:repository_path].delete_suffix('.git')
      query = request.query_string

      git_request?(query) && container_path?(path)
    end

    # Allow /info/refs, /info/refs?service=git-upload-pack, and
    # /info/refs?service=git-receive-pack, but nothing else.
    def git_request?(query)
      query.blank? ||
        query == 'service=git-upload-pack' ||
        query == 'service=git-receive-pack'
    end

    # Check if the path matches any known repository containers.
    def container_path?(path)
      wiki_path?(path) ||
        ProjectPathValidator.valid_path?(path) ||
        path =~ Gitlab::PathRegex.full_snippets_repository_path_regex
    end

    private

    # These also cover wikis, since a `.wiki` suffix is valid in project/group paths too.
    def wiki_path?(path)
      NamespacePathValidator.valid_path?(path) && path.end_with?('.wiki')
    end
  end
end
