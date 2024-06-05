# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Limit
          class Deployments < Chain::Base
            extend ::Gitlab::Utils::Override
            include ::Gitlab::Ci::Pipeline::Chain::Helpers

            attr_reader :limit
            private :limit

            def initialize(*)
              super

              @limit = ::Gitlab::Ci::Pipeline::Quota::Deployments
                .new(project.namespace, pipeline, command)
            end

            override :perform!
            def perform!
              return unless limit.exceeded?

              limit.log_error!(project_id: project.id, plan: project.actual_plan_name)
              error(limit.message, failure_reason: :deployments_limit_exceeded)
            end

            override :break?
            def break?
              limit.exceeded?
            end
          end
        end
      end
    end
  end
end
