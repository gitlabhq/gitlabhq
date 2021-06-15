# frozen_string_literal: true

class ClusterApplicationEntity < Grape::Entity
  expose :name
  expose :status_name, as: :status
  expose :status_reason
  expose :version, if: -> (e, _) { e.respond_to?(:version) }
  expose :external_ip, if: -> (e, _) { e.respond_to?(:external_ip) }
  expose :external_hostname, if: -> (e, _) { e.respond_to?(:external_hostname) }
  expose :hostname, if: -> (e, _) { e.respond_to?(:hostname) }
  expose :email, if: -> (e, _) { e.respond_to?(:email) }
  expose :stack, if: -> (e, _) { e.respond_to?(:stack) }
  expose :update_available?, as: :update_available, if: -> (e, _) { e.respond_to?(:update_available?) }
  expose :can_uninstall?, as: :can_uninstall
  expose :available_domains, using: Serverless::DomainEntity, if: -> (e, _) { e.respond_to?(:available_domains) }
  expose :pages_domain, using: Serverless::DomainEntity, if: -> (e, _) { e.respond_to?(:pages_domain) }
  expose :host, if: -> (e, _) { e.respond_to?(:host) }
  expose :port, if: -> (e, _) { e.respond_to?(:port) }
  expose :protocol, if: -> (e, _) { e.respond_to?(:protocol) }
end
