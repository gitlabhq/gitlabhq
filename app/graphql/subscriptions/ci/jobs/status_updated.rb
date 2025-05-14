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
          job = force(GitlabSchema.find_by_gid(job_id))

          unauthorized! unless job && Ability.allowed?(current_user, :read_build, job)

          true
        end
      end
    end
  end
end
