# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class GuestPackageEventCounter < BaseCounter
      KNOWN_EVENTS_PATH = File.expand_path('counter_events/guest_package_events.yml', __dir__)
      KNOWN_EVENTS = YAML.safe_load(File.read(KNOWN_EVENTS_PATH)).freeze
      PREFIX = 'package_guest'
    end
  end
end
