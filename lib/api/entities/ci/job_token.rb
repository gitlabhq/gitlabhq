# frozen_string_literal: true

module API
  module Entities
    module Ci
      class JobToken < Grape::Entity
        expose :job, with: ::API::Entities::Ci::JobBasic

        def job
          object
        end
      end
    end
  end
end
