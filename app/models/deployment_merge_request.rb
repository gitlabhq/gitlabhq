# frozen_string_literal: true

class DeploymentMergeRequest < ApplicationRecord
  belongs_to :deployment, optional: false
  belongs_to :merge_request, optional: false

  def self.join_deployments_for_merge_requests
    joins(deployment: :environment)
      .where('deployment_merge_requests.merge_request_id = merge_requests.id')
  end

  def self.by_deployment_id(id)
    where('deployments.id = ?', id)
  end

  def self.deployed_to(name)
    where('environments.name = ?', name)
  end

  def self.deployed_after(time)
    where('deployments.finished_at > ?', time)
  end

  def self.deployed_before(time)
    where('deployments.finished_at < ?', time)
  end
end
