module Mattermost
  class SlashCommandService < BaseService
    def self.command(command, sub_command, klass, help_message)
      registry[command][sub_command] = { klass: klass, help_message: help_message }
    end

    command 'issue', 'show',    Mattermost::Commands::IssueShowService,   'issue show <id>'
    command 'issue', 'search',  Mattermost::Commands::IssueSearchService, 'issue search <query>'
    command 'issue', 'create',  Mattermost::Commands::IssueCreateService, 'issue create my title'

    command 'mergerequest', 'show',   Mattermost::Commands::MergeRequestShowService,    'mergerequest show <id>'
    command 'mergerequest', 'search', Mattermost::Commands::MergeRequestSearchService,  'mergerequest search <query>'

    def execute
      service = registry[command][subcommand]

      return help_messages(registry) unless service.try(:available?)

      service.new(project, current_user, params).execute
    end

    private

    def self.registry
      @registry ||= Hash.new({})
    end
  end
end
