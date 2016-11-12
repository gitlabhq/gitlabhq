module Mattermost
  class CommandService < BaseService
    SERVICES = [
      Mattermost::Commands::IssueService,
      Mattermost::Commands::MergeRequestService
    ]

    def execute
      return unknown_user unless current_user
      return not_found_404 unless can?(current_user, :read_project, project)

      triggered_command = command
      service = SERVICES.find do |service|
        service.triggered_by?(triggered_command) && service.available?(project)
      end

      if service
        present service.new(project, current_user, params).execute
      else
        help_message
      end
    end

    private

    def command
      params[:text].split.first
    end

    def present(result)
      return not_found_404 unless result

      if result.respond_to?(:count)
        if count > 1
          # TODO
          return resource_list(result)
        else
          result = result.first
        end
      end

      message = "### [#{result.to_reference} #{result.title}](link(result))"
      message << "\n\n#{result.description}" if result.description

      {
        response_type: :in_channel,
        text: message
      }
    end

    def unknown_user
      {
        response_type: :ephemeral,
        text: 'Hi there! I have not yet had the pleasure to get acquainted!' # TODO allow user to authenticate and authorize
      }
    end

    def not_found_404
      {
        response_type: :ephemeral,
        text: "404 not found! GitLab couldn't find what your were looking for! :boom:",
      }
    end

    def help_message
      command_help_messages = SERVICES.map { |service| service.help_message(project) }

      {
        response_type: :ephemeral,
        text: "Sadly, the used command does not exist, lets take a look at your options here:\n\n#{command_help_messages.join("\n")}"
      }
    end
  end
end
