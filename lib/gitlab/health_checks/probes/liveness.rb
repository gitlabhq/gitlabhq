# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Probes
      class Liveness
        def execute
          Probes::Status.new(200, status: 'ok')
        end
      end
    end
  end
end
