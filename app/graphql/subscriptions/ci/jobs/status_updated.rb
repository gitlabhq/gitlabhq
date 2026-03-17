# frozen_string_literal: true

module Subscriptions
  module Ci
    module Jobs
      class StatusUpdated < ::Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :job_id, ::Types::GlobalIDType[::Ci::Build],
          required: true,
          description: 'Global ID of the job.'

        payload_type Types::Ci::JobType

        def authorized?(job_id:)
          authorize_object_or_gid!(:read_build, gid: job_id)
        end
      end
    end
  end
end
