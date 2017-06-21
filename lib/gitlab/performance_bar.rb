module Gitlab
  module PerformanceBar
    def self.enabled?(current_user = nil)
      Feature.enabled?(:gitlab_performance_bar, current_user)
    end

    def self.allowed_actor?(actor)
      group = allowed_group
      return false unless actor&.is_a?(User) && group

      GroupMembersFinder.new(group)
        .execute
        .where(user_id: actor.id)
        .any?
    end

    def self.allowed_group
      return nil unless Gitlab.config.performance_bar.allowed_group

      Group.by_path(Gitlab.config.performance_bar.allowed_group)
    end
  end
end
