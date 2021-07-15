# frozen_string_literal: true

class Packages::Event < ApplicationRecord
  belongs_to :package, optional: true

  UNIQUE_EVENTS_ALLOWED = %i[push_package delete_package pull_package pull_symbol_package push_symbol_package].freeze
  EVENT_SCOPES = ::Packages::Package.package_types.merge(container: 1000, tag: 1001).freeze

  EVENT_PREFIX = "i_package"

  enum event_scope: EVENT_SCOPES

  enum event_type: {
    push_package: 0,
    delete_package: 1,
    pull_package: 2,
    search_package: 3,
    list_package: 4,
    list_repositories: 5,
    delete_repository: 6,
    delete_tag: 7,
    delete_tag_bulk: 8,
    list_tags: 9,
    cli_metadata: 10,
    pull_symbol_package: 11,
    push_symbol_package: 12
  }

  enum originator_type: { user: 0, deploy_token: 1, guest: 2 }

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

  # total counter names for tracking number of events
  def self.counters_for(event_scope, event_type, originator_type)
    return [] unless event_allowed?(event_type)

    [
      "#{EVENT_PREFIX}_#{event_type}",
      "#{EVENT_PREFIX}_#{event_type}_by_#{originator_type}",
      "#{EVENT_PREFIX}_#{event_scope}_#{event_type}"
    ]
  end
end
