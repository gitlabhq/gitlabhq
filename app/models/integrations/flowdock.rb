# frozen_string_literal: true

# This integration is scheduled for removal.
# All records must be deleted before the class can be removed.
# https://gitlab.com/gitlab-org/gitlab/-/issues/379197
module Integrations
  class Flowdock < Integration
    def readonly?
      true
    end

    def self.to_param
      'flowdock'
    end

    def self.supported_events
      %w[]
    end
  end
end
