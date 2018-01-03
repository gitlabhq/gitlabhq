class DeploymentSerializer < BaseSerializer
  entity DeploymentEntity

  def represent_concise(resource, opts = {})
    opts[:only] = [:iid, :id, :sha, :created_at, :tag, :last?, :first?, :id, ref: [:name]]
    represent(resource, opts)
  end
end
