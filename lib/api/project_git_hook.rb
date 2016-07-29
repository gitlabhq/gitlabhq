# TODO: These end-points are deprecated and replaced with push_rules
# and should be removed after  GitLab 9.0 is released

module API
  # Projects push rule API
  class ProjectGitHook < Grape::API
    before { authenticate! }
    before { authorize_admin_project }

    resource :projects do
      # Get project push rule
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/push_rule
      get ":id/git_hook" do
        @push_rule = user_project.push_rule
        present @push_rule, with: Entities::ProjectPushRule
      end

      # Add push rule to project
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   POST /projects/:id/push_rule
      post ":id/git_hook" do
        attrs = attributes_for_keys [
          :commit_message_regex,
          :deny_delete_tag
        ]

        if user_project.push_rule
          error!("Project push rule exists", 422)
        else
          @push_rule = user_project.create_push_rule(attrs)
          present @push_rule, with: Entities::ProjectPushRule
        end
      end

      # Update an existing project push rule
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   PUT /projects/:id/push_rule
      put ":id/git_hook" do
        @push_rule = user_project.push_rule

        attrs = attributes_for_keys [
          :commit_message_regex,
          :deny_delete_tag
        ]

        if @push_rule && @push_rule.update_attributes(attrs)
          present @push_rule, with: Entities::ProjectPushRule
        else
          not_found!
        end
      end

      # Deletes project push rule. This is an idempotent function.
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   DELETE /projects/:id/push_rule
      delete ":id/git_hook" do
        @push_rule = user_project.push_rule
        if @push_rule
          @push_rule.destroy
        else
          not_found!
        end
      end
    end
  end
end
