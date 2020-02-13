# frozen_string_literal: true

module Gitlab
  class GitAccessSnippet < GitAccess
    ERROR_MESSAGES = {
      snippet_not_found: 'The snippet you were looking for could not be found.',
      repository_not_found: 'The snippet repository you were looking for could not be found.'
    }.freeze

    attr_reader :snippet

    def initialize(actor, snippet, protocol, **kwargs)
      @snippet = snippet

      super(actor, project, protocol, **kwargs)
    end

    def check(cmd, _changes)
      unless Feature.enabled?(:version_snippets, user)
        raise NotFoundError, ERROR_MESSAGES[:snippet_not_found]
      end

      check_snippet_accessibility!

      success_result(cmd)
    end

    def project
      snippet&.project
    end

    private

    def repository
      snippet&.repository
    end

    def check_snippet_accessibility!
      if snippet.blank?
        raise NotFoundError, ERROR_MESSAGES[:snippet_not_found]
      end

      unless repository&.exists?
        raise NotFoundError, ERROR_MESSAGES[:repository_not_found]
      end
    end
  end
end
