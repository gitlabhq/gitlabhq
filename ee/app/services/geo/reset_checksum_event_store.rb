# frozen_string_literal: true

module Geo
  class ResetChecksumEventStore < EventStore
    self.event_type = :reset_checksum_event

    private

    def build_event
      Geo::ResetChecksumEvent.new(project: project)
    end
  end
end
