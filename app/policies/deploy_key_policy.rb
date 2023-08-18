# frozen_string_literal: true

class DeployKeyPolicy < BasePolicy
  with_options scope: :subject, score: 0
  condition(:private_deploy_key) { @subject.private? }
  condition(:public_deploy_key) { @subject.public? }
  condition(:has_deploy_key) { @user.project_deploy_keys.any? { |pdk| pdk.id.eql?(@subject.id) } }

  rule { anonymous }.prevent_all
  rule { public_deploy_key | admin | has_deploy_key }.policy do
    enable :read_deploy_key
  end
  rule { admin | (private_deploy_key & has_deploy_key) }.policy do
    enable :update_deploy_key
  end
end
