# frozen_string_literal: true

class ProjectHookPolicy < ::BasePolicy
  delegate(:project)

  rule { can?(:admin_project) }.policy do
    enable :read_web_hook
    enable :destroy_web_hook
  end
end
