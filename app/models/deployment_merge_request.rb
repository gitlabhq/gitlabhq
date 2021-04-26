# frozen_string_literal: true

class DeploymentMergeRequest < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  belongs_to :deployment, optional: false
  belongs_to :merge_request, optional: false

  def self.join_deployments_for_merge_requests
    joins(deployment: :environment)
      .where('deployment_merge_requests.merge_request_id = merge_requests.id')
  end

  def self.by_deployment_id(id)
    where(deployments: { id: id })
  end

  def self.deployed_to(name)
    # We filter by project ID again so the query uses the index on
    # (project_id, name), instead of using the index on
    # (name varchar_pattern_ops). This results in better performance on
    # GitLab.com.
    where(environments: { name: name })
      .where('environments.project_id = merge_requests.target_project_id')
  end

  def self.deployed_after(time)
    where('deployments.finished_at > ?', time)
  end

  def self.deployed_before(time)
    where('deployments.finished_at < ?', time)
  end
end
