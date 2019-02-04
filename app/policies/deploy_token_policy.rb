# frozen_string_literal: true

class DeployTokenPolicy < BasePolicy
  with_options scope: :subject, score: 0
  condition(:maintainer) { @subject.project.team.maintainer?(@user) }

  rule { anonymous }.prevent_all

  rule { maintainer }.policy do
    enable :create_deploy_token
    enable :update_deploy_token
  end
end
