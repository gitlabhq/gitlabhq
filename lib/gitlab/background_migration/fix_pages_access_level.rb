# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # corrects stored pages access level on db depending on project visibility
    class FixPagesAccessLevel
      # Copy routable here to avoid relying on application logic
      module Routable
        def build_full_path
          if parent && path
            parent.build_full_path + '/' + path
          else
            path
          end
        end
      end

      # Namespace
      class Namespace < ApplicationRecord
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled

        include Routable

        belongs_to :parent, class_name: "Namespace"
      end

      # Project
      class Project < ActiveRecord::Base
        self.table_name = 'projects'
        self.inheritance_column = :_type_disabled

        include Routable

        belongs_to :namespace
        alias_method :parent, :namespace
        alias_attribute :parent_id, :namespace_id

        PRIVATE = 0
        INTERNAL = 10
        PUBLIC = 20

        def pages_deployed?
          Dir.exist?(public_pages_path)
        end

        def public_pages_path
          File.join(pages_path, 'public')
        end

        def pages_path
          # TODO: when we migrate Pages to work with new storage types, change here to use disk_path
          File.join(Settings.pages.path, build_full_path)
        end
      end

      # ProjectFeature
      class ProjectFeature < ActiveRecord::Base
        include ::EachBatch

        self.table_name = 'project_features'

        belongs_to :project

        PRIVATE = 10
        ENABLED = 20
        PUBLIC  = 30
      end

      def perform(start_id, stop_id)
        fix_public_access_level(start_id, stop_id)

        make_internal_projects_public(start_id, stop_id)

        fix_private_access_level(start_id, stop_id)
      end

      private

      def access_control_is_enabled
        @access_control_is_enabled = Gitlab.config.pages.access_control
      end

      # Public projects are allowed to have only enabled pages_access_level
      # which is equivalent to public
      def fix_public_access_level(start_id, stop_id)
        project_features(start_id, stop_id, ProjectFeature::PUBLIC, Project::PUBLIC).each_batch do |features|
          features.update_all(pages_access_level: ProjectFeature::ENABLED)
        end
      end

      # If access control is disabled and project has pages deployed
      # project will become unavailable when access control will become enabled
      # we make these projects public to avoid negative surprise to user
      def make_internal_projects_public(start_id, stop_id)
        return if access_control_is_enabled

        project_features(start_id, stop_id, ProjectFeature::ENABLED, Project::INTERNAL).find_each do |project_feature|
          next unless project_feature.project.pages_deployed?

          project_feature.update(pages_access_level: ProjectFeature::PUBLIC)
        end
      end

      # Private projects are not allowed to have enabled access level, only `private` and `public`
      # If access control is enabled, these projects currently behave as if the have `private` pages_access_level
      # if access control is disabled, these projects currently behave as if the have `public` pages_access_level
      # so we preserve this behaviour for projects with pages already deployed
      # for project without pages we always set `private` access_level
      def fix_private_access_level(start_id, stop_id)
        project_features(start_id, stop_id, ProjectFeature::ENABLED, Project::PRIVATE).find_each do |project_feature|
          if access_control_is_enabled
            project_feature.update!(pages_access_level: ProjectFeature::PRIVATE)
          else
            fixed_access_level = project_feature.project.pages_deployed? ? ProjectFeature::PUBLIC : ProjectFeature::PRIVATE
            project_feature.update!(pages_access_level: fixed_access_level)
          end
        end
      end

      def project_features(start_id, stop_id, pages_access_level, project_visibility_level)
        ProjectFeature.where(id: start_id..stop_id).joins(:project)
          .where(pages_access_level: pages_access_level)
          .where(projects: { visibility_level: project_visibility_level })
      end
    end
  end
end
