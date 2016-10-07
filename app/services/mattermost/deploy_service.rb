module Mattermost
  class DeployService < BaseService
    def execute
      environment_name, action_name = parse_command
      return respond_404 unless environment_name

      environment = project.environments.find_by(name: environment_name)

      return respond_404 unless can?(current_user, :read_environment, environment)

      deployment = environment.last_deployment
      return respond_404 unless can?(current_user, :create_deployment, deployment) && deployment.deployable

      build = environment.last_deployment.manual_actions.find { |action| action.name = action_name }
      return {
        response_type: :ephemeral,
        text: "No action '#{action_name}' defined for #{environment_name}."
      } unless build

      new_build = build.play(current_user)

      {
        response_type: :in_channel,
        text: "Action '#{action_name}' started on '#{environment_name}' you can [follow the progress](#{link(new_build)})."
      }
    end

    private

    def single_resource(build)
      {
        response_type: :in_channel,
        message: "Deploy started [#{build.name} ##{build.id}](#{link(build)})"
      }
    end

    def link(build)
      Gitlab::Routing.
        url_helpers.
        namespace_project_build_url(project.namespace, project, build)
    end

    def parse_command
      matches = params[:text].match(/\A(?<name>\w+) to (?<action>\w+)/)
      return unless matches

      return matches[:name], matches[:action]
    end
  end
end
