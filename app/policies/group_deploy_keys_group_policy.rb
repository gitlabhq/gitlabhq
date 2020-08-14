# frozen_string_literal: true

class GroupDeployKeysGroupPolicy < BasePolicy
  with_options scope: :subject, score: 0
  delegate { @subject.group }
  condition(:user_is_group_owner) { @subject.group.has_owner?(@user) }

  rule { user_is_group_owner }.enable :update_group_deploy_key_for_group
end
