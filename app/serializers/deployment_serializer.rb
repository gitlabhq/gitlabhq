# frozen_string_literal: true

class DeploymentSerializer < BaseSerializer
  entity DeploymentEntity

  def represent_concise(resource, opts = {})
    opts[:only] = [:iid, :id, :sha, :created_at, :deployed_at, :tag, :last?, :is_last, :id, { ref: [:name] }]
    represent(resource, opts)
  end
end
