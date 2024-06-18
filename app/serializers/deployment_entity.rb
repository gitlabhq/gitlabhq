# frozen_string_literal: true

class DeploymentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :sha

  expose :ref do
    expose :name do |deployment|
      deployment.ref
    end

    expose :ref_path do |deployment|
      project_tree_path(deployment.project, id: deployment.ref)
    end
  end

  expose :status
  expose :created_at
  expose :deployed_at
  expose :tag
  expose :last?
  expose :last?, as: :is_last
  expose :tier_in_yaml

  expose :deployed_by, as: :user, using: UserEntity

  expose :deployable, if: ->(deployment) { deployment.deployable.present? } do |deployment, opts|
    deployment.deployable.then do |deployable|
      if include_details?
        Ci::JobEntity.represent(deployable, opts)
      elsif can_read_deployables?
        { name: deployable.name,
          build_path: project_job_path(deployable.project, deployable) }
      end
    end
  end

  expose :commit, using: CommitEntity, if: ->(*) { include_details? }
  expose :manual_actions, using: Ci::JobEntity, if: ->(*) { include_details? && can_create_deployment? }
  expose :scheduled_actions, using: Ci::JobEntity, if: ->(*) { include_details? && can_create_deployment? }
  expose :playable_job, as: :playable_build, if: ->(deployment) { include_details? && can_create_deployment? && deployment.playable_job } do |deployment, options|
    Ci::JobEntity.represent(deployment.playable_job, options.merge(only: [:play_path, :retry_path]))
  end

  expose :cluster do |deployment, options|
    # Until data is copied over from deployments.cluster_id, this entity must represent Deployment instead of DeploymentCluster
    # https://gitlab.com/gitlab-org/gitlab/issues/202628
    DeploymentClusterEntity.represent(deployment, options) unless deployment.cluster.nil?
  end

  expose :web_path do |deployment|
    project_environment_deployment_path(project, deployment.environment, deployment)
  end

  private

  def include_details?
    options.fetch(:deployment_details, true)
  end

  def can_create_deployment?
    can?(request.current_user, :create_deployment, project)
  end

  def can_read_deployables?
    ##
    # We intentionally do not check `:read_build, deployment.deployable`
    # because it triggers a policy evaluation that involves multiple
    # Gitaly calls that might not be cached.
    #
    can?(request.current_user, :read_build, project)
  end

  def project
    request.try(:project) || options[:project]
  end
end

DeploymentEntity.prepend_mod
