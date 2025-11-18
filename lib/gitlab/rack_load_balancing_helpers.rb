# frozen_string_literal: true

module Gitlab
  module RackLoadBalancingHelpers
    def load_balancer_stick_request(model, namespace, id, hash_id: false)
      request.env[::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT] ||= Set.new
      request.env[::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT] << [model.sticking, namespace, id]

      model
        .sticking
        .find_caught_up_replica(namespace, id, hash_id: hash_id)
    end
  end
end
