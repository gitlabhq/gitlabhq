# frozen_string_literal: true

class DeploymentSerializer < BaseSerializer
  entity DeploymentEntity

  def represent_concise(resource, opts = {})
    opts[:only] = [:iid, :id, :sha, :created_at, :finished_at, :tag, :last?, :id, ref: [:name]]
    represent(resource, opts)
  end
end
