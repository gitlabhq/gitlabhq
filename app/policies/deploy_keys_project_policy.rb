# frozen_string_literal: true

class DeployKeysProjectPolicy < BasePolicy
  delegate { @subject.project }

  with_options scope: :subject, score: 0
  condition(:public_deploy_key) { @subject.deploy_key.public? }

  rule { public_deploy_key & can?(:admin_project) }.enable :update_deploy_keys_project
end
