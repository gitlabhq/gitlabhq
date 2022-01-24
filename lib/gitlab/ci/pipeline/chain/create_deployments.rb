# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CreateDeployments < Chain::Base
          def perform!
            create_deployments!
          end

          def break?
            false
          end

          private

          def create_deployments!
            pipeline.stages.map(&:statuses).flatten.map(&method(:create_deployment))
          end

          def create_deployment(build)
            ::Deployments::CreateForBuildService.new.execute(build)
          end
        end
      end
    end
  end
end
