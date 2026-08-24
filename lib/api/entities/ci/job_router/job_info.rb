# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRouter
        # Job info for the internal Job Router job request endpoint.
        #
        # Adds the tags the job asked for, which runner controllers use to make
        # admission decisions. They are not part of the public runner job response.
        class JobInfo < ::API::Entities::Ci::JobRequest::JobInfo
          expose(
            :tags,
            documentation: { type: 'String', is_array: true, example: %w[docker linux] }
          ) do |build|
            build.tag_list.to_a
          end
        end
      end
    end
  end
end
