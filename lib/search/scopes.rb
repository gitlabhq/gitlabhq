# frozen_string_literal: true

module Search
  # Central registry for search scopes across all search contexts
  # Provides a single source of truth for scope definitions, availability,
  # and validation logic
  class Scopes
    # Scope definitions with metadata (CE scopes only)
    # Format: { scope_key => { label:, sort:, availability: } }
    # availability maps context (:global, :group, :project) to supported search types
    # EE scopes are defined in ee/lib/ee/search/scopes.rb
    SCOPE_DEFINITIONS = {
      projects: {
        label: -> { _('Projects') },
        sort: 1,
        availability: {
          global: %i[zoekt advanced basic],
          group: %i[zoekt advanced basic]
        }
      },
      blobs: {
        label: -> { _('Code') },
        sort: 2,
        availability: {
          global: %i[zoekt advanced],
          group: %i[zoekt advanced],
          project: %i[zoekt advanced basic]
        }
      },
      # sort: 3 is reserved for EE scopes (epics)
      issues: {
        label: -> { _('Issues') },
        sort: 4,
        availability: {
          global: %i[zoekt advanced basic],
          group: %i[zoekt advanced basic],
          project: %i[zoekt advanced basic]
        }
      },
      merge_requests: {
        label: -> { _('Merge requests') },
        sort: 5,
        availability: {
          global: %i[zoekt advanced basic],
          group: %i[zoekt advanced basic],
          project: %i[zoekt advanced basic]
        }
      },
      wiki_blobs: {
        label: -> { _('Wiki') },
        sort: 6,
        availability: {
          global: %i[zoekt advanced],
          group: %i[zoekt advanced],
          project: %i[zoekt advanced basic]
        }
      },
      commits: {
        label: -> { _('Commits') },
        sort: 7,
        availability: {
          global: %i[zoekt advanced],
          group: %i[zoekt advanced],
          project: %i[zoekt advanced basic]
        }
      },
      notes: {
        label: -> { _('Comments') },
        sort: 8,
        availability: {
          global: %i[zoekt advanced],
          group: %i[zoekt advanced],
          project: %i[zoekt advanced basic]
        }
      },
      milestones: {
        label: -> { _('Milestones') },
        sort: 9,
        availability: {
          global: %i[zoekt advanced basic],
          group: %i[zoekt advanced basic],
          project: %i[zoekt advanced basic]
        }
      },
      users: {
        label: -> { _('Users') },
        sort: 10,
        availability: {
          global: %i[zoekt advanced basic],
          group: %i[zoekt advanced basic],
          project: %i[zoekt advanced basic]
        }
      },
      snippet_titles: {
        label: -> { _('Snippets') },
        sort: 11,
        availability: {
          global: %i[zoekt advanced basic],
          group: %i[zoekt advanced basic]
        }
      }
    }.freeze

    # Map of scopes to their required application setting for global search (CE scopes)
    # EE scopes are added in ee/lib/ee/search/scopes.rb
    GLOBAL_SEARCH_SETTING_MAP = {
      'issues' => :global_search_issues_enabled?,
      'merge_requests' => :global_search_merge_requests_enabled?,
      'snippet_titles' => :global_search_snippet_titles_enabled?,
      'users' => :global_search_users_enabled?
    }.freeze

    class << self
      # Get all scope names
      def all_scope_names
        scope_definitions.keys.map(&:to_s)
      end

      # Get scopes available for a specific context (global, group, project)
      # @param context [Symbol] :global, :group, or :project
      # @param container [Project, Group, nil] The container being searched (optional)
      # @param requested_search_type [String, Symbol] User's requested search type (optional)
      # @return [Array<String>] Array of scope names available for the context
      def available_for_context(context:, container: nil, requested_search_type: nil)
        scope_definitions.select do |scope, definition|
          valid_definition?(scope, definition, context, container, requested_search_type)
        end.keys.map(&:to_s)
      end

      # Check if a scope should be hidden when work_item_scope_frontend is enabled
      # @param scope [Symbol] Scope key to check
      # @param user [User] current user for feature flag checks (optional)
      # @return [Boolean] True if scope should be hidden
      def hidden_by_work_item_scope?(scope, user = nil)
        return false unless user
        return false unless ::Feature.enabled?(:work_item_scope_frontend, user)

        # When work_item_scope_frontend is enabled, issues and epics are hidden
        # as they become sub-items under "Work items"
        [:issues, :epics].include?(scope)
      end

      # Returns the scope definitions (can be overridden in EE)
      def scope_definitions
        SCOPE_DEFINITIONS
      end

      private

      # Returns the global search setting map (can be overridden in EE)
      def global_search_setting_map
        GLOBAL_SEARCH_SETTING_MAP
      end

      # Check if a scope definition is valid for the given context and search capabilities
      # @param scope [Symbol] Scope key (e.g., :issues, :epics)
      # @param definition [Hash] Scope definition
      # @param context [Symbol] :global, :group, or :project
      # @param container [Project, Group, nil] The container being searched
      # @param requested_search_type [String, Symbol] User's explicitly requested search type
      # @return [Boolean] True if the definition is valid
      def valid_definition?(scope, definition, context, _container, requested_search_type = nil)
        availability = definition[:availability]
        return false if availability[context].blank?
        return false if context == :global && global_search_disabled_for_scope?(scope)

        # Verify if requested_search_type is present then it should be basic
        return false unless requested_search_type.blank? || requested_search_type.to_sym == :basic

        # In CE, only basic search is available
        availability[context].include?(:basic)
      end

      # Check if global search is disabled for a specific scope
      # @param scope [Symbol] Scope key to check
      # @return [Boolean] True if global search is disabled for this scope
      def global_search_disabled_for_scope?(scope)
        setting_method = global_search_setting_map[scope.to_s]
        setting_method && !::Gitlab::CurrentSettings.public_send(setting_method) # rubocop:disable GitlabSecurity/PublicSend -- setting_method is validated from GLOBAL_SEARCH_SETTING_MAP
      end
    end
  end
end

Search::Scopes.prepend_mod
