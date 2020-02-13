# frozen_string_literal: true

module API
  module Entities
    module JobRequest
      class Step < Grape::Entity
        expose :name, :script, :timeout, :when, :allow_failure
      end
    end
  end
end
