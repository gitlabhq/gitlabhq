# frozen_string_literal: true

module QA
  module Resource
    module KubernetesCluster
      class Base < Resource::Base
        attr_writer :add_name_uuid

        attribute :id
        attribute :name
        attribute :domain
        attribute :enabled
        attribute :managed
        attribute :management_project_id

        attribute :api_url
        attribute :token
        attribute :ca_cert
        attribute :namespace

        attribute :authorization_type
        attribute :environment_scope

        def initialize
          @add_name_uuid = true
          @enabled = true
          @managed = true
          @authorization_type = :rbac
          @environment_scope = :*
        end

        def name=(new_name)
          @name = @add_name_uuid ? "#{new_name}-#{SecureRandom.hex(5)}" : new_name
        end
      end
    end
  end
end
