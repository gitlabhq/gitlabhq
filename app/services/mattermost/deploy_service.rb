module Mattermost
  class DeployService < BaseService
    def execute
      environment_name, action_name = parse_command
      environment = project.environments.find_by(name: environment_name)
      return respond_404 unless can?(current_user, :read_environment, environment)

      deployment = environment.last_deployment
      return respond_404 unless can?(current_user, :create_deployment, deployment)

      build = deployment.manual_actions.find { |action| action.name = action_name }

      if build
        new_build = build.play(current_user)
        generate_response(new_build)
      else
        {
          response_type: :ephemeral,
          text: "No action '#{action_name}' defined for #{environment_name}."
        }
      end
    end

    private

    def single_resource(build)
      {
        response_type: :in_channel,
        text: "Action '#{action_name}' started on '#{environment_name}' you can [follow the progress](#{link(new_build)})."
      }
    end

    def link(build)
      Gitlab::Routing.
        url_helpers.
        namespace_project_build_url(project.namespace, project, build)
    end

    def parse_command
      matches = params[:text].match(/\A(?<name>\w+) to (?<action>\w+)/)

      matches ? [matches[:name], matches[:action]] : nil
    end
  end
end
