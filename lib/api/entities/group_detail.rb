# frozen_string_literal: true

module API
  module Entities
    class GroupDetail < Group
      expose :shared_with_groups do |group, options|
        SharedGroupWithGroup.represent(group.shared_with_group_links.public_or_visible_to_user(group, options[:current_user]))
      end
      expose :runners_token, if: lambda { |group, options| options[:user_can_admin_group] }
      expose :prevent_sharing_groups_outside_hierarchy, if: ->(group) { group.root? }

      expose :projects, using: Entities::Project do |group, options|
        projects = GroupProjectsFinder.new(
          group: group,
          current_user: options[:current_user],
          options: { only_owned: true, limit: projects_limit }
        ).execute

        Entities::Project.prepare_relation(projects)
      end

      expose :shared_projects, using: Entities::Project do |group, options|
        projects = GroupProjectsFinder.new(
          group: group,
          current_user: options[:current_user],
          options: { only_shared: true, limit: projects_limit }
        ).execute

        Entities::Project.prepare_relation(projects)
      end

      def projects_limit
        GroupProjectsFinder::DEFAULT_PROJECTS_LIMIT
      end
    end
  end
end

API::Entities::GroupDetail.prepend_mod_with('API::Entities::GroupDetail')
