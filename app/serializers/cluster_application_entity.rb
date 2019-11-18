# frozen_string_literal: true

class ClusterApplicationEntity < Grape::Entity
  expose :name
  expose :status_name, as: :status
  expose :status_reason
  expose :version
  expose :external_ip, if: -> (e, _) { e.respond_to?(:external_ip) }
  expose :external_hostname, if: -> (e, _) { e.respond_to?(:external_hostname) }
  expose :hostname, if: -> (e, _) { e.respond_to?(:hostname) }
  expose :kibana_hostname, if: -> (e, _) { e.respond_to?(:kibana_hostname) }
  expose :email, if: -> (e, _) { e.respond_to?(:email) }
  expose :stack, if: -> (e, _) { e.respond_to?(:stack) }
  expose :update_available?, as: :update_available, if: -> (e, _) { e.respond_to?(:update_available?) }
  expose :can_uninstall?, as: :can_uninstall
end
