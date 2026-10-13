# frozen_string_literal: true

module Gitlab
  module Import
    # Detects how an import/migration was initiated, for the `request_channel`
    # internal event property (API vs. UI vs. Congregate). Congregate is a
    # Professional Services migration tool that itself calls the API; it is
    # identified by its User-Agent.
    #
    # Callers pass an explicit :ui from web controllers; API endpoints call
    # `.detect(request)` to distinguish plain API from Congregate.
    module RequestChannel
      API = :api
      UI = :ui
      CONGREGATE = :congregate

      # Congregate uses gitlab-ps-utils' GitLabApi client, which defaults
      # its User-Agent to "GitLabApiClient" (gitlab_ps_utils/api.py). Match
      # that as a prefix so future client versions carrying a suffix
      # (e.g. "GitLabApiClient/2.0") still resolve to :congregate.
      #
      # Best-effort heuristic, not a reliable identifier: any tool built on
      # that same shared library, not just Congregate, would send this
      # User-Agent and be misattributed to :congregate. Follow-up #630340
      # tracks having Congregate send a dedicated header instead.
      CONGREGATE_USER_AGENT_PATTERN = /\AGitLabApiClient\b/

      REQUEST_STORE_KEY = :import_request_channel

      def self.detect(request)
        return CONGREGATE if congregate?(request)

        API
      end

      def self.congregate?(request)
        user_agent = request&.user_agent
        return false if user_agent.blank?

        CONGREGATE_USER_AGENT_PATTERN.match?(user_agent)
      end

      # Hands the channel from Import::BaseService to ProjectImportState#after_create
      # within the same request, since Rails autosave creates the import state.
      def self.stash(value)
        Gitlab::SafeRequestStore[REQUEST_STORE_KEY] = value
      end

      def self.stashed
        Gitlab::SafeRequestStore[REQUEST_STORE_KEY]
      end
    end
  end
end
