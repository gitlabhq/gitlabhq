# frozen_string_literal: true

module API
  module Entities
    class Todo < Grape::Entity
      expose :id
      expose :project, using: Entities::ProjectIdentity, if: ->(todo, _) { todo.project_id }
      expose :group, using: 'API::Entities::NamespaceBasic', if: ->(todo, _) { todo.group_id }
      expose :author, using: Entities::UserBasic
      expose :action_name
      expose :target_type

      expose :target do |todo, options|
        todo_options = options.fetch(todo.target_type, {})
        todo_target_class(todo.target_type).represent(todo.target, todo_options)
      end

      expose :target_url

      expose :body
      expose :state
      expose :created_at
      expose :updated_at

      def todo_target_class(target_type)
        # Ensure the `Key` type properly maps to the `SSHKey` entity
        target_type = "SSHKey" if target_type == "Key"
        # false as second argument prevents looking up in module hierarchy
        # see also https://gitlab.com/gitlab-org/gitlab-foss/issues/59719
        ::API::Entities.const_get(target_type, false)
      end

      def todo_target_anchor(todo)
        "note_#{todo.note_id}" if todo.note_id?
      end

      def design_todo_target_url(todo)
        design = todo.target
        path_options = {
          anchor: todo_target_anchor(todo),
          vueroute: design.filename
        }

        ::Gitlab::Routing.url_helpers.designs_project_issue_url(design.project, design.issue, path_options)
      end
    end
  end
end

API::Entities::Todo.prepend_mod_with('API::Entities::Todo')
