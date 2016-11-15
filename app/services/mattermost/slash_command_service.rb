module Mattermost
  class SlashCommandService < BaseService
    def self.registry
      @registry ||= Hash.new({})
    end

    def self.command(command, sub_command, klass, help_message)
      registry[command][sub_command] = { klass: klass, help_message: help_message }
    end

    command 'issue', 'show',    Mattermost::Commands::IssueShowService,   'issue show <id>'
    command 'issue', 'search',  Mattermost::Commands::IssueSearchService, 'issue search <query>'
    command 'issue', 'create',  Mattermost::Commands::IssueCreateService, 'issue create my title'

    command 'mergerequest', 'show',   Mattermost::Commands::MergeRequestShowService,    'mergerequest show <id>'
    command 'mergerequest', 'search', Mattermost::Commands::MergeRequestSearchService,  'mergerequest search <query>'

    def execute
      command, subcommand = parse_command

      #TODO think how to do this to support ruby 2.1
      service = registry.dig(command, subcommand, :klass)

      return help_messages(registry) unless service.try(:available?, project)

      service.new(project, current_user, params).execute
    end

    private

    def parse_command
      params[:text].split.first(2)
    end

    def registry
      self.class.registry
    end
  end
end
