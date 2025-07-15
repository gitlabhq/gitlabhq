# frozen_string_literal: true

module ContainerRegistry
  module Protection
    module Concerns
      module TagRule
        extend ActiveSupport::Concern

        private

        def protected_patterns_for_delete(project:, current_user: nil)
          return if user_can_admin_all_resources?(current_user, project)

          tag_rules = ::ContainerRegistry::Protection::TagRule.tag_name_patterns_for_project(project.id)
          tag_rules = fetch_eligible_tag_rules_for_project(tag_rules, project, current_user)

          if current_user && !current_user.can_admin_all_resources?
            user_access_level = project.team.max_member_access(current_user.id)
            tag_rules = tag_rules.for_delete_and_access(user_access_level)
          end

          return if tag_rules.blank?

          tag_rules.map { |rule| ::Gitlab::UntrustedRegexp.new(rule.tag_name_pattern) }
        end

        def protected_for_delete?(project:, current_user:)
          return false if current_user.can_admin_all_resources?

          return false unless project.has_container_registry_protected_tag_rules?(
            action: 'delete',
            access_level: project.team.max_member_access(current_user.id)
          )

          project.has_container_registry_tags?
        end

        def user_can_admin_all_resources?(user, _project)
          user&.can_admin_all_resources?
        end

        def fetch_eligible_tag_rules_for_project(tag_rules, _project, _user)
          tag_rules.mutable
        end
      end
    end
  end
end

ContainerRegistry::Protection::Concerns::TagRule.prepend_mod
