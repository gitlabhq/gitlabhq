# frozen_string_literal: true

class ClusterSerializer < BaseSerializer
  include WithPagination
  entity ClusterEntity

  def represent_list(resource)
    represent(resource, {
      only: [
        :cluster_type,
        :enabled,
        :environment_scope,
        :id,
        :kubernetes_errors,
        :name,
        :nodes,
        :path,
        :provider_type,
        :status
      ]
    })
  end

  def represent_status(resource)
    represent(resource, { only: [:status, :status_reason] })
  end
end
