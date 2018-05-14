class DeployTokenPolicy < BasePolicy
  with_options scope: :subject, score: 0
  condition(:master) { @subject.project.team.master?(@user) }

  rule { anonymous }.prevent_all

  rule { master }.policy do
    enable :create_deploy_token
    enable :update_deploy_token
  end
end
