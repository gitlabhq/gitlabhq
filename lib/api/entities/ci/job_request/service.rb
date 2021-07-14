# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Service < Entities::Ci::JobRequest::Image
          expose :alias, :command
        end
      end
    end
  end
end
