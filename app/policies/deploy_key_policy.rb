# frozen_string_literal: true

class DeployKeyPolicy < BasePolicy
  with_options scope: :subject, score: 0
  condition(:private_deploy_key) { @subject.private? }
  condition(:public_deploy_key) { @subject.public? }
  condition(:has_deploy_key) { @user.project_deploy_keys.any? { |pdk| pdk.id.eql?(@subject.id) } }
  condition(:orphaned_deploy_key) { @subject.orphaned? }
  condition(:is_maintainer_of_deploy_key_project) do
    # Note: 'almost_orphaned' deploy key has only one project record and we can check it as 'first'
    @subject.almost_orphaned? && can?(:maintainer_access, @subject.deploy_keys_projects.first)
  end

  rule { anonymous }.prevent_all
  rule { public_deploy_key | admin | has_deploy_key }.policy do
    enable :read_deploy_key
  end
  rule { admin | (private_deploy_key & has_deploy_key) }.policy do
    enable :update_deploy_key
  end
  rule { can?(:update_deploy_key) & (admin | orphaned_deploy_key | is_maintainer_of_deploy_key_project) }.policy do
    enable :update_deploy_key_title
  end
end
