# frozen_string_literal: true

module ContainerRegistry
  module Protection
    module Concerns
      module TagRule
        extend ActiveSupport::Concern

        private

        def protected_patterns_for_delete(project:, current_user: nil)
          tag_rules = ContainerRegistry::Protection::TagRule.tag_name_patterns_for_project(project.id)

          if current_user
            return if current_user.can_admin_all_resources?

            user_access_level = project.team.max_member_access(current_user.id)
            tag_rules = tag_rules.for_delete_and_access(user_access_level)
          end

          return if tag_rules.blank?

          tag_rules.map { |rule| ::Gitlab::UntrustedRegexp.new(rule.tag_name_pattern) }
        end

        def protected_for_delete?(project:, current_user:)
          if Feature.enabled?(:container_registry_immutable_tags, project) &&
              project.container_registry_protection_tag_rules.immutable.present? &&
              project.has_container_registry_tags?
            return true
          end

          return false if current_user.can_admin_all_resources?

          return false unless project.has_container_registry_protected_tag_rules?(
            action: 'delete',
            access_level: project.team.max_member_access(current_user.id),
            include_immutable: false
          )

          project.has_container_registry_tags?
        end
      end
    end
  end
end
