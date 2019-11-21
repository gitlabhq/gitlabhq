# frozen_string_literal: true

class ProjectAutoDevops < ApplicationRecord
  belongs_to :project, inverse_of: :auto_devops

  enum deploy_strategy: {
    continuous: 0,
    manual: 1,
    timed_incremental: 2
  }

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  after_save :create_gitlab_deploy_token, if: :needs_to_create_deploy_token?

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'AUTO_DEVOPS_EXPLICITLY_ENABLED', value: '1') if enabled?
      variables.concat(deployment_strategy_default_variables)
    end
  end

  private

  def create_gitlab_deploy_token
    project.deploy_tokens.create!(
      name: DeployToken::GITLAB_DEPLOY_TOKEN_NAME,
      read_registry: true
    )
  end

  def needs_to_create_deploy_token?
    project.auto_devops_enabled? &&
      !project.public? &&
      !project.deploy_tokens.find_by(name: DeployToken::GITLAB_DEPLOY_TOKEN_NAME).present?
  end

  def deployment_strategy_default_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      if manual?
        variables.append(key: 'STAGING_ENABLED', value: '1')
        variables.append(key: 'INCREMENTAL_ROLLOUT_ENABLED', value: '1') # deprecated
        variables.append(key: 'INCREMENTAL_ROLLOUT_MODE', value: 'manual')
      elsif timed_incremental?
        variables.append(key: 'INCREMENTAL_ROLLOUT_MODE', value: 'timed')
      end
    end
  end
end
