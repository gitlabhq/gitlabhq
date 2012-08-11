module Gitlab
  # Issues API
  class Issues < Grape::API
    before { authenticate! }

    resource :issues do
      # Get currently authenticated user's issues
      #
      # Example Request:
      #   GET /issues
      get do
        present current_user.issues, with: Entities::Issue
      end
    end

    resource :projects do
      # Get a list of project issues
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      # Example Request:
      #   GET /projects/:id/issues
      get ":id/issues" do
        present user_project.issues, with: Entities::Issue
      end

      # Get a single project issue
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   issue_id (required) - The ID of a project issue
      # Example Request:
      #   GET /projects/:id/issues/:issue_id
      get ":id/issues/:issue_id" do
        @issue = user_project.issues.find(params[:issue_id])
        present @issue, with: Entities::Issue
      end

      # Create a new project issue
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   title (required) - The title of an issue
      #   description (optional) - The description of an issue
      #   assignee_id (optional) - The ID of a user to assign issue
      #   milestone_id (optional) - The ID of a milestone to assign issue
      #   labels (optional) - The labels of an issue
      # Example Request:
      #   POST /projects/:id/issues
      post ":id/issues" do
        @issue = user_project.issues.new(
          title: params[:title],
          description: params[:description],
          assignee_id: params[:assignee_id],
          milestone_id: params[:milestone_id],
          label_list: params[:labels]
        )
        @issue.author = current_user

        if @issue.save
          present @issue, with: Entities::Issue
        else
          error!({'message' => '404 Not found'}, 404)
        end
      end

      # Update an existing issue
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   issue_id (required) - The ID of a project issue
      #   title (optional) - The title of an issue
      #   description (optional) - The description of an issue
      #   assignee_id (optional) - The ID of a user to assign issue
      #   milestone_id (optional) - The ID of a milestone to assign issue
      #   labels (optional) - The labels of an issue
      #   closed (optional) - The state of an issue (0 = false, 1 = true)
      # Example Request:
      #   PUT /projects/:id/issues/:issue_id
      put ":id/issues/:issue_id" do
        @issue = user_project.issues.find(params[:issue_id])
        parameters = {
          title: (params[:title] || @issue.title),
          description: (params[:description] || @issue.description),
          assignee_id: (params[:assignee_id] || @issue.assignee_id),
          milestone_id: (params[:milestone_id] || @issue.milestone_id),
          label_list: (params[:labels] || @issue.label_list),
          closed: (params[:closed] || @issue.closed)
        }

        if @issue.update_attributes(parameters)
          present @issue, with: Entities::Issue
        else
          error!({'message' => '404 Not found'}, 404)
        end
      end

      # Delete a project issue
      #
      # Parameters:
      #   id (required) - The ID or code name of a project
      #   issue_id (required) - The ID of a project issue
      # Example Request:
      #   DELETE /projects/:id/issues/:issue_id
      delete ":id/issues/:issue_id" do
        @issue = user_project.issues.find(params[:issue_id])
        @issue.destroy
      end
    end
  end
end
