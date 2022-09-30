# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Runner < Grape::Entity
        expose :id
        expose :description
        expose :ip_address
        expose :active # TODO Remove in v5 in favor of `paused` for REST calls, see https://gitlab.com/gitlab-org/gitlab/-/issues/375709
        expose :paused do |runner|
          !runner.active
        end
        expose :instance_type?, as: :is_shared
        expose :runner_type
        expose :name
        expose :online?, as: :online
        # DEPRECATED
        # TODO Remove in v5 in favor of `status` for REST calls, see https://gitlab.com/gitlab-org/gitlab/-/issues/375709
        expose :deprecated_rest_status, as: :status
      end
    end
  end
end
