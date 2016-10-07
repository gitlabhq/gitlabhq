module Mattermost
  class DeployService < BaseService
    def execute
      environment_name, action_name = parse_command
      environment = project.environments.find_by(name: environment_name)

      return respond_404 unless can?(current_user, :read_environment, environment)

      deployment = environment.last_deployment
      return respond_404 unless can?(current_user, :create_deployment, deployment) && deployment.deployable

      build = environment.last_deployment.other_actions.find { |action| action.name = action_name }

      generate_response(build.play(current_user))
    end

    private

    def single_resource(build)
      {
        response_type: :in_channel,
        text: "Deploy started: "
      }
    end

    def parse_command
      matches = params[:text].match(/\A\/deploy (?<name>\w+) to (?<action>\w+)/)
      respond_404 unless matches

      return matches[:name], matches[:action]
    end
  end
end
