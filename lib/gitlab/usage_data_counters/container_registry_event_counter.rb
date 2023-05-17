# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class ContainerRegistryEventCounter < BaseCounter
      KNOWN_EVENTS = %w[i_container_registry_delete_manifest].freeze
      PREFIX = 'container_registry_events'
    end
  end
end
