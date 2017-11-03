module EE
  module ProjectsHelper
    def can_force_update_mirror?(project)
      return true if project.mirror_hard_failed?
      return true unless project.mirror_last_update_at

      Time.now - project.mirror_last_update_at >= 5.minutes
    end

    def can_change_push_rule?(push_rule, rule)
      return true if push_rule.global?

      can?(current_user, :"change_#{rule}", @project)
    end
  end
end
