# frozen_string_literal: true

module Packages
  class Event
    UNIQUE_EVENTS_ALLOWED = %i[push_package delete_package pull_package pull_symbol_package push_symbol_package].freeze
    EVENT_SCOPES = ::Packages::Package.package_types.merge(container: 1000, tag: 1001, dependency_proxy: 1002).freeze

    EVENT_PREFIX = "i_package"

    EVENT_TYPES = %i[
      push_package
      delete_package
      pull_package
      search_package
      list_package
      list_repositories
      delete_repository
      delete_tag
      delete_tag_bulk
      list_tags
      create_tag
      cli_metadata
      pull_symbol_package
      push_symbol_package
      pull_manifest
      pull_manifest_from_cache
      pull_blob
      pull_blob_from_cache
    ].freeze

    ORIGINATOR_TYPES = %i[user deploy_token guest].freeze

    # Remove some of the events, for now, so we don't hammer Redis too hard.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/280770
    def self.event_allowed?(event_type)
      return true if UNIQUE_EVENTS_ALLOWED.include?(event_type.to_sym)

      false
    end

    # counter names for unique user tracking (for MAU)
    def self.unique_counters_for(event_scope, event_type, originator_type)
      return [] unless event_allowed?(event_type)
      return [] if originator_type.to_s == 'guest'

      ["#{EVENT_PREFIX}_#{event_scope}_#{originator_type}"]
    end
  end
end
