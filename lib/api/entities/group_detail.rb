# frozen_string_literal: true

module API
  module Entities
    class GroupDetail < Group
      expose :shared_with_groups do |group, options|
        SharedGroupWithGroup.represent(group.shared_with_group_links.public_or_visible_to_user(group, options[:current_user]))
      end
      expose :runners_token, if: lambda { |group, options| options[:user_can_admin_group] }
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
        if ::Feature.enabled?(:limit_projects_in_groups_api, default_enabled: true)
          GroupProjectsFinder::DEFAULT_PROJECTS_LIMIT
        else
          nil
        end
      end
    end
  end
end

API::Entities::GroupDetail.prepend_if_ee('EE::API::Entities::GroupDetail')
