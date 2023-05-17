# frozen_string_literal: true

class ProjectHookPolicy < ::BasePolicy
  delegate { @subject.project }

  rule { can?(:admin_project) }.policy do
    enable :destroy_web_hook
  end
end
