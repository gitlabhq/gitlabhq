# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRouter
        # Response payload for the internal Job Router job request endpoint.
        #
        # It inherits from the public runner job response (so it also includes the
        # EE-only fields already prepended onto the parent) and overrides the parts
        # the Job Router needs to carry more than the runner does. Being a dedicated
        # entity, it can diverge further without touching the public runner API.
        class JobResponse < ::API::Entities::Ci::JobRequest::Response
          expose :job_info, using: ::API::Entities::Ci::JobRouter::JobInfo, override: true do |model|
            model
          end

          expose :runner_info, using: ::API::Entities::Ci::JobRouter::RunnerInfo, override: true do |model|
            model
          end
        end
      end
    end
  end
end
