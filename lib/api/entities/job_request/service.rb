# frozen_string_literal: true

module API
  module Entities
    module JobRequest
      class Service < Entities::JobRequest::Image
        expose :alias, :command
      end
    end
  end
end
