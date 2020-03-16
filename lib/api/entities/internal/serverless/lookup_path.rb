# frozen_string_literal: true

module API
  module Entities
    module Internal
      module Serverless
        class LookupPath < Grape::Entity
          expose :source
        end
      end
    end
  end
end
