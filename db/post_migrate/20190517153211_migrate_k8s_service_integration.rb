# frozen_string_literal: true

class MigrateK8sServiceIntegration < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class Cluster < ActiveRecord::Base
    self.table_name = 'clusters'

    has_one :platform_kubernetes, class_name: 'MigrateK8sServiceIntegration::PlatformsKubernetes'

    accepts_nested_attributes_for :platform_kubernetes

    enum cluster_type: {
      instance_type: 1,
      group_type: 2,
      project_type: 3
    }

    enum platform_type: {
      kubernetes: 1
    }

    enum provider_type: {
      user: 0,
      gcp: 1
    }
  end

  class PlatformsKubernetes < ActiveRecord::Base
    self.table_name = 'cluster_platforms_kubernetes'

    belongs_to :cluster, class_name: 'MigrateK8sServiceIntegration::Cluster'

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_truncated,
      algorithm: 'aes-256-cbc'
  end

  class Service < ActiveRecord::Base
    include EachBatch

    self.table_name = 'services'
    self.inheritance_column = :_type_disabled # Disable STI, otherwise KubernetesModel will be looked up

    belongs_to :project, class_name: 'MigrateK8sServiceIntegration::Project', foreign_key: :project_id

    scope :kubernetes_service_templates, -> do
      where(category: 'deployment', type: 'KubernetesService', template: true)
    end

    def api_url
      parsed_properties['api_url'].presence
    end

    def ca_pem
      parsed_properties['ca_pem']
    end

    def namespace
      parsed_properties['namespace'].presence
    end

    def token
      parsed_properties['token'].presence
    end

    private

    def parsed_properties
      @parsed_properties ||= JSON.parse(self.properties) # rubocop:disable Gitlab/Json
    end
  end

  def up
    has_instance_cluster = Cluster.instance_type.where(enabled: true).exists?

    MigrateK8sServiceIntegration::Service.kubernetes_service_templates.find_each do |service|
      next unless service.api_url && service.token

      MigrateK8sServiceIntegration::Cluster.create!(
        enabled: !has_instance_cluster && service.active,
        managed: false,
        name: 'KubernetesService',
        cluster_type: 'instance_type',
        provider_type: 'user',
        platform_type: 'kubernetes',
        platform_kubernetes_attributes: {
          api_url: service.api_url,
          ca_cert: service.ca_pem,
          namespace: service.namespace,
          token: service.token
        }
      )
    end
  end

  def down
    # It is not possible to tell which instance-level clusters were created by
    # this migration. The original data is intentionally left intact.
  end
end
