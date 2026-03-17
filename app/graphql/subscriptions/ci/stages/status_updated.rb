# frozen_string_literal: true

module Subscriptions
  module Ci
    module Stages
      class StatusUpdated < ::Subscriptions::BaseSubscription
        include Gitlab::Graphql::Laziness

        argument :stage_id, ::Types::GlobalIDType[::Ci::Stage],
          required: true,
          description: 'Global ID of the stage.'

        payload_type Types::Ci::StageType

        def authorized?(stage_id:)
          authorize_object_or_gid!(:read_build, gid: stage_id)
        end

        def update(stage_id:)
          stage = force(object)

          return NO_UPDATE unless stage
          return NO_UPDATE unless stage.id == stage_id.model_id.to_i

          stage
        end
      end
    end
  end
end
