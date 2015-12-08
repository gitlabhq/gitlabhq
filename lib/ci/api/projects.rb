module Ci
  module API
    # Projects API
    class Projects < Grape::API
      before { authenticate! }

      resource :projects do
        # Register new webhook for project
        #
        # Parameters
        #   project_id (required) - The ID of a project
        #   web_hook (required) - WebHook URL
        # Example Request
        #   POST /projects/:project_id/webhooks
        post ":project_id/webhooks" do
          required_attributes! [:web_hook]

          project = Ci::Project.find(params[:project_id])

          unauthorized! unless can?(current_user, :admin_project, project.gl_project)

          web_hook = project.web_hooks.new({ url: params[:web_hook] })

          if web_hook.save
            present web_hook, with: Entities::WebHook
          else
            errors = web_hook.errors.full_messages.join(", ")
            render_api_error!(errors, 400)
          end
        end

        # Retrieve all Gitlab CI projects that the user has access to
        #
        # Example Request:
        #   GET /projects
        get do
          gitlab_projects = current_user.authorized_projects
          gitlab_projects = filter_projects(gitlab_projects)
          gitlab_projects = paginate gitlab_projects

          ids = gitlab_projects.map { |project| project.id }

          projects = Ci::Project.where("gitlab_id IN (?)", ids).load
          present projects, with: Entities::Project
        end

        # Retrieve all Gitlab CI projects that the user owns
        #
        # Example Request:
        #   GET /projects/owned
        get "owned" do
          gitlab_projects = current_user.owned_projects
          gitlab_projects = filter_projects(gitlab_projects)
          gitlab_projects = paginate gitlab_projects

          ids = gitlab_projects.map { |project| project.id }

          projects = Ci::Project.where("gitlab_id IN (?)", ids).load
          present projects, with: Entities::Project
        end

        # Retrieve info for a Gitlab CI project
        #
        # Parameters:
        #   id (required) - The ID of a project
        # Example Request:
        #   GET /projects/:id
        get ":id" do
          project = Ci::Project.find(params[:id])
          unauthorized! unless can?(current_user, :read_project, project.gl_project)

          present project, with: Entities::Project
        end

        # Create Gitlab CI project using Gitlab project info
        #
        # Parameters:
        #   gitlab_id (required)       - The gitlab id of the project
        #   default_ref                - The branch to run against (defaults to `master`)
        # Example Request:
        #   POST /projects
        post do
          required_attributes! [:gitlab_id]

          filtered_params = {
            gitlab_id:       params[:gitlab_id],
            # we accept gitlab_url for backward compatibility for a while (added to 7.11)
            default_ref:     params[:default_ref] || 'master'
          }

          project = Ci::Project.new(filtered_params)
          project.build_missing_services

          if project.save
            present project, with: Entities::Project
          else
            errors = project.errors.full_messages.join(", ")
            render_api_error!(errors, 400)
          end
        end

        # Update a Gitlab CI project
        #
        # Parameters:
        #   id (required)   - The ID of a project
        #   default_ref      - The branch to run against (defaults to `master`)
        # Example Request:
        #   PUT /projects/:id
        put ":id" do
          project = Ci::Project.find(params[:id])

          unauthorized! unless can?(current_user, :admin_project, project.gl_project)

          attrs = attributes_for_keys [:default_ref]

          if project.update_attributes(attrs)
            present project, with: Entities::Project
          else
            errors = project.errors.full_messages.join(", ")
            render_api_error!(errors, 400)
          end
        end

        # Remove a Gitlab CI project
        #
        # Parameters:
        #   id (required) - The ID of a project
        # Example Request:
        #   DELETE /projects/:id
        delete ":id" do
          project = Ci::Project.find(params[:id])

          unauthorized! unless can?(current_user, :admin_project, project.gl_project)

          project.destroy
        end

        # Link a Gitlab CI project to a runner
        #
        # Parameters:
        #   id (required) - The ID of a CI project
        #   runner_id (required) - The ID of a runner
        # Example Request:
        #   POST /projects/:id/runners/:runner_id
        post ":id/runners/:runner_id" do
          project = Ci::Project.find(params[:id])
          runner  = Ci::Runner.find(params[:runner_id])

          unauthorized! unless can?(current_user, :admin_project, project.gl_project)

          options = {
            project_id: project.id,
            runner_id:  runner.id
          }

          runner_project = Ci::RunnerProject.new(options)

          if runner_project.save
            present runner_project, with: Entities::RunnerProject
          else
            errors = project.errors.full_messages.join(", ")
            render_api_error!(errors, 400)
          end
        end

        # Remove a Gitlab CI project from a runner
        #
        # Parameters:
        #   id (required) - The ID of a CI project
        #   runner_id (required) - The ID of a runner
        # Example Request:
        #   DELETE /projects/:id/runners/:runner_id
        delete ":id/runners/:runner_id" do
          project = Ci::Project.find(params[:id])
          runner  = Ci::Runner.find(params[:runner_id])

          unauthorized! unless can?(current_user, :admin_project, project.gl_project)

          options = {
            project_id: project.id,
            runner_id:  runner.id
          }

          runner_project = Ci::RunnerProject.find_by(options)

          if runner_project.present?
            runner_project.destroy
          else
            not_found!
          end
        end
      end
    end
  end
end
