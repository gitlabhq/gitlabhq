# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRouter
        # Response payload for the internal Job Router job request endpoint.
        #
        # It currently inherits from the public runner job response (so it also includes
        # the EE-only fields already prepended onto the parent), but as a dedicated entity
        # that the Job Router owns it can diverge and expose Job Router-only fields
        # independently of the public runner API.
        class JobResponse < ::API::Entities::Ci::JobRequest::Response
        end
      end
    end
  end
end
