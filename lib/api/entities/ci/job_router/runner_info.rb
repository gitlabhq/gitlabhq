# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRouter
        # Runner info for the internal Job Router job request endpoint.
        #
        # Adds the tags the assigned runner offers, which runner controllers use to
        # make admission decisions. They are not part of the public runner job response.
        class RunnerInfo < ::API::Entities::Ci::JobRequest::RunnerInfo
          expose(
            :tags,
            documentation: { type: 'String', is_array: true, example: %w[docker linux gpu] }
          ) do |build|
            build.runner.tag_list.to_a
          end
        end
      end
    end
  end
end
