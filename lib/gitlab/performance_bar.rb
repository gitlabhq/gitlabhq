module Gitlab
  module PerformanceBar
    def self.enabled?(current_user = nil)
      Feature.enabled?(:gitlab_performance_bar, current_user)
    end

    def self.allowed_actor?(actor)
      return false unless actor.thing&.is_a?(User) && allowed_group

      if RequestStore.active?
        RequestStore.fetch('performance_bar:user_member_of_allowed_group') do
          user_member_of_allowed_group?(actor.thing)
        end
      else
        user_member_of_allowed_group?(actor.thing)
      end
    end

    def self.allowed_group
      return nil unless Gitlab.config.performance_bar.allowed_group

      if RequestStore.active?
        RequestStore.fetch('performance_bar:allowed_group') do
          Group.by_path(Gitlab.config.performance_bar.allowed_group)
        end
      else
        Group.by_path(Gitlab.config.performance_bar.allowed_group)
      end
    end

    def self.user_member_of_allowed_group?(user)
      GroupMembersFinder.new(allowed_group)
        .execute
        .where(user_id: user.id)
        .any?
    end
  end
end
