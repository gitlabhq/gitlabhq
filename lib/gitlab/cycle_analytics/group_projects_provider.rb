# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module GroupProjectsProvider
      def projects
        group ? projects_for_group : [project]
      end

      def group
        @group ||= options.fetch(:group, nil)
      end

      def project
        @project ||= options.fetch(:project, nil)
      end

      private

      def projects_for_group
        projects = Project.inside_path(group.full_path)
        projects = projects.where(id: options[:projects]) if options[:projects]
        projects
      end
    end
  end
end
