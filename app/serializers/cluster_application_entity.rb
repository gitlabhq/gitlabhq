# frozen_string_literal: true

class ClusterApplicationEntity < Grape::Entity
  expose :name
  expose :status_name, as: :status
  expose :status_reason
  expose :external_ip, if: -> (e, _) { e.respond_to?(:external_ip) }
  expose :hostname, if: -> (e, _) { e.respond_to?(:hostname) }
end
