# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class RunnerInfo < Grape::Entity
          expose :timeout_value, as: :timeout
          expose :runner_session_url
        end
      end
    end
  end
end
