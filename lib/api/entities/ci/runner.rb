# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Runner < Grape::Entity
        expose :id
        expose :description
        expose :ip_address
        expose :active
        expose :instance_type?, as: :is_shared
        expose :runner_type
        expose :name
        expose :online?, as: :online
        # DEPRECATED
        # TODO Remove in %15.0 in favor of `status` for REST calls, see https://gitlab.com/gitlab-org/gitlab/-/issues/344648
        expose :status, as: :deprecated_rest_status
      end
    end
  end
end
