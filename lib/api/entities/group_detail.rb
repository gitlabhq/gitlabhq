# frozen_string_literal: true

module API
  module Entities
    class GroupDetail < Group
      expose :shared_with_groups do |group, options|
        SharedGroupWithGroup.represent(group.shared_with_group_links_visible_to_user(options[:current_user]))
      end
      expose :runners_token, if: ->(_, options) { options[:user_can_admin_group] }
      expose :enabled_git_access_protocol, if: ->(group, options) { group.root? && options[:user_can_admin_group] }
      expose :prevent_sharing_groups_outside_hierarchy,
        if: ->(group) { group.root? && group.namespace_settings.present? }

      expose :projects,
        if: ->(_, options) { options[:with_projects] },
        using: Entities::Project do |group, options|
        projects = GroupProjectsFinder.new(
          group: group,
          current_user: options[:current_user],
          options: { exclude_shared: true, limit: projects_limit }
        ).execute

        Entities::Project.prepare_relation(projects, options)
      end

      expose :shared_projects,
        if: ->(_, options) { options[:with_projects] },
        using: Entities::Project do |group, options|
        projects = GroupProjectsFinder.new(
          group: group,
          current_user: options[:current_user],
          options: { only_shared: true, limit: projects_limit }
        ).execute

        Entities::Project.prepare_relation(projects, options)
      end

      def projects_limit
        GroupProjectsFinder::DEFAULT_PROJECTS_LIMIT
      end
    end
  end
end

API::Entities::GroupDetail.prepend_mod_with('API::Entities::GroupDetail')
