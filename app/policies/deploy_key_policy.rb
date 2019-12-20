# frozen_string_literal: true

class DeployKeyPolicy < BasePolicy
  with_options scope: :subject, score: 0
  condition(:private_deploy_key) { @subject.private? }
  condition(:has_deploy_key) { @user.project_deploy_keys.any? { |pdk| pdk.id.eql?(@subject.id) } }

  rule { anonymous }.prevent_all

  rule { admin }.enable :update_deploy_key
  rule { private_deploy_key & has_deploy_key }.enable :update_deploy_key
end
