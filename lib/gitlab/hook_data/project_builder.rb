# frozen_string_literal: true

module Gitlab
  module HookData
    class ProjectBuilder < BaseBuilder
      alias_method :project, :object

      # Sample data
      # {
      #   event_name: "project_rename",
      #   created_at: "2021-04-19T07:05:36Z",
      #   updated_at: "2021-04-19T07:05:36Z",
      #   name: "my_project",
      #   path: "my_project",
      #   path_with_namespace: "namespace2/my_project",
      #   project_id: 1,
      #   owner_name: "John",
      #   owner_email: "user1@example.org",
      #   project_visibility: "internal",
      #   old_path_with_namespace: "old-path-with-namespace"
      # }

      def build(event)
        [
          event_data(event),
          timestamps_data,
          project_data,
          event_specific_project_data(event)
        ].reduce(:merge)
      end

      private

      def project_data
        owner = project.owner

        {
          name: project.name,
          path: project.path,
          path_with_namespace: project.full_path,
          project_id: project.id,
          owner_name: owner.name,
          owner_email: owner.respond_to?(:email) ? owner.email : "",
          project_visibility: project.visibility.downcase
        }
      end

      def event_specific_project_data(event)
        return {} unless event == :rename || event == :transfer

        {
          old_path_with_namespace: project.old_path_with_namespace
        }
      end
    end
  end
end
