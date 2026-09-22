# frozen_string_literal: true

module Gitlab
  module Metrics
    module GlobalSearchSlis
      include Gitlab::Metrics::SliConfig

      puma_enabled!

      class << self
        # The following targets are the 99.95th percentile of code searches
        # gathered on 25-10-2022
        # from https://log.gprd.gitlab.net/goto/0c89cd80-23af-11ed-8656-f5f2137823ba (internal only)
        BASIC_CONTENT_TARGET_S = 8.812
        BASIC_MR_TARGET_S = 15
        BASIC_CODE_TARGET_S = 27.538
        ADVANCED_CONTENT_TARGET_S = 2.452
        ADVANCED_CODE_TARGET_S = 15.52
        ZOEKT_TARGET_S = 15.52
        # Not a percentile of anything, unlike the constants above: this is what
        # a combination is scored against when no target has been derived for it.
        DEFAULT_TARGET_S = 5

        # Autocomplete reports nil type/level/scope, so it derives no target and
        # took DEFAULT_TARGET_S by accident. Named so the 5 is a choice for this
        # endpoint, and a scope added later cannot inherit it.
        AUTOCOMPLETE_TARGET_S = 5
        AUTOCOMPLETE_ENDPOINT_ID = 'SearchController#autocomplete'

        def initialize_slis!
          all_labels = possible_labels + autocomplete_labels

          Gitlab::Metrics::Sli::Apdex.initialize_sli(:global_search, all_labels)
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:global_search, all_labels)
        end

        def record_apdex(elapsed:, search_type:, search_level:, search_scope:)
          target = duration_target(search_type, search_scope)
          success = elapsed < target

          Gitlab::Metrics::Sli::Apdex[:global_search].increment(
            labels: labels(search_type: search_type, search_level: search_level, search_scope: search_scope),
            success: success
          )

          Gitlab::AppJsonLogger.info(
            message: "Global Search Apdex SLI",
            duration_s: elapsed,
            target_s: target,
            success: success,
            search_type: search_type,
            search_level: search_level,
            search_scope: search_scope
          )
        end

        def record_error_rate(error:, search_type:, search_level:, search_scope:)
          Gitlab::Metrics::Sli::ErrorRate[:global_search].increment(
            labels: labels(search_type: search_type, search_level: search_level, search_scope: search_scope),
            error: error
          )

          Gitlab::AppJsonLogger.info(
            message: "Global Search Error Rate SLI",
            error: error,
            search_type: search_type,
            search_level: search_level,
            search_scope: search_scope
          )
        end

        private

        def duration_target(search_type, search_scope)
          return AUTOCOMPLETE_TARGET_S if endpoint_id == AUTOCOMPLETE_ENDPOINT_ID

          derived_duration_target(search_type, search_scope) || DEFAULT_TARGET_S
        end

        # Returns nil rather than DEFAULT_TARGET_S for an unknown combination, so
        # a caller can tell a derived target from a fallthrough. The three of them
        # that currently equal 5 are indistinguishable by value alone.
        def derived_duration_target(search_type, search_scope)
          if search_type == 'basic' && search_scope == 'merge_requests'
            BASIC_MR_TARGET_S
          elsif search_type == 'basic' && content_search?(search_scope)
            BASIC_CONTENT_TARGET_S
          elsif search_type == 'basic' && code_search?(search_scope)
            BASIC_CODE_TARGET_S
          elsif search_type == 'advanced' && content_search?(search_scope)
            ADVANCED_CONTENT_TARGET_S
          elsif search_type == 'advanced' && code_search?(search_scope)
            ADVANCED_CODE_TARGET_S
          elsif search_type == 'zoekt' && code_search?(search_scope)
            ZOEKT_TARGET_S
          end
        end

        def search_types
          ::SearchService.supported_search_types
        end

        def search_levels
          %w[project group global]
        end

        def search_scopes
          ::Search::Scopes.all_scope_names
        end

        def endpoint_ids
          api_endpoints = ['GET /api/:version/search', 'GET /api/:version/projects/:id/(-/)search',
            'GET /api/:version/groups/:id/(-/)search']
          web_endpoints = ['SearchController#show', 'SearchController#count']

          endpoints = []

          endpoints += api_endpoints if Gitlab::Metrics::Environment.api?
          endpoints += web_endpoints if Gitlab::Metrics::Environment.web?

          endpoints
        end

        def possible_labels
          search_types.flat_map do |search_type|
            search_levels.flat_map do |search_level|
              search_scopes.flat_map do |search_scope|
                next [] unless valid_search_type?(search_type, search_scope, search_level)

                endpoint_ids.map do |endpoint_id|
                  {
                    search_type: search_type,
                    search_level: search_level,
                    search_scope: search_scope,
                    endpoint_id: endpoint_id
                  }
                end
              end
            end
          end
        end

        def autocomplete_labels
          return [] unless Gitlab::Metrics::Environment.web?

          [{
            search_type: nil,
            search_level: nil,
            search_scope: nil,
            endpoint_id: AUTOCOMPLETE_ENDPOINT_ID
          }]
        end

        def valid_search_type?(search_type, search_scope, search_level)
          definition = ::Search::Scopes.scope_definitions[search_scope.to_sym]
          definition[:availability].fetch(search_level.to_sym, []).include?(search_type.to_sym)
        end

        def labels(search_type:, search_level:, search_scope:)
          {
            search_type: search_type,
            search_level: search_level,
            search_scope: search_scope,
            endpoint_id: endpoint_id
          }
        end

        def endpoint_id
          ::Gitlab::ApplicationContext.current_context_attribute(:caller_id)
        end

        def code_search?(search_scope)
          search_scope == 'blobs'
        end

        def content_search?(search_scope)
          !code_search?(search_scope)
        end
      end
    end
  end
end

Gitlab::Metrics::GlobalSearchSlis.prepend_mod
