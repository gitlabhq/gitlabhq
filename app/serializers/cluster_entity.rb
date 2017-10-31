class ClusterEntity < Grape::Entity
  include RequestAwareEntity

  expose :status_name, as: :status
  expose :status_reason
  expose :applications do |cluster, options|
    if cluster.created?
      {
        helm: { status: 'installed' },
        ingress: { status: 'error', status_reason: 'Missing namespace' },
        runner: { status: 'installing' },
        prometheus: { status: 'installable' }
      }
    else
      {}
    end
  end
end
