# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Runner < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 8 }
        expose :description, documentation: { type: 'string', example: 'test-1-20150125' }
        # TODO: remove in v5 https://gitlab.com/gitlab-org/gitlab/-/issues/415159
        expose(:ip_address, documentation: { type: 'string', example: '127.0.0.1' }) { |_runner, _options| nil }
        # TODO Remove in v5 in favor of `paused` for REST calls, see https://gitlab.com/gitlab-org/gitlab/-/issues/375709
        expose :active, documentation: { type: 'boolean', example: true }
        expose :paused, documentation: { type: 'boolean', example: false } do |runner|
          !runner.active
        end
        expose :instance_type?, as: :is_shared, documentation: { type: 'boolean', example: true }
        expose :runner_type,
          documentation: { type: 'string', values: ::Ci::Runner.runner_types.keys, example: 'instance_type' }
        expose :name, documentation: { type: 'string', example: 'test' }
        expose :online?, as: :online, documentation: { type: 'boolean', example: true }
        # DEPRECATED
        # TODO Remove in v5 in favor of `status` for REST calls, see https://gitlab.com/gitlab-org/gitlab/-/issues/375709
        expose :deprecated_rest_status, as: :status, documentation: { type: 'string', example: 'online' }
      end
    end
  end
end
