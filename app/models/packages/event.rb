# frozen_string_literal: true

class Packages::Event < ApplicationRecord
  belongs_to :package, optional: true

  UNIQUE_EVENTS_ALLOWED = %i[push_package delete_package pull_package].freeze
  EVENT_SCOPES = ::Packages::Package.package_types.merge(container: 1000, tag: 1001).freeze

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
    cli_metadata: 10
  }

  enum originator_type: { user: 0, deploy_token: 1, guest: 2 }

  def self.allowed_event_name(event_scope, event_type, originator)
    return unless event_allowed?(event_type)

    # remove `package` from the event name to avoid issues with HLLRedisCounter class parsing
    "i_package_#{event_scope}_#{originator}_#{event_type.gsub(/_packages?/, "")}"
  end

  # Remove some of the events, for now, so we don't hammer Redis too hard.
  # See: https://gitlab.com/gitlab-org/gitlab/-/issues/280770
  def self.event_allowed?(event_type)
    return true if UNIQUE_EVENTS_ALLOWED.include?(event_type.to_sym)

    false
  end
end
