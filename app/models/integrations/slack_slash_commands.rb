# frozen_string_literal: true

module Integrations
  # Stub class to prevent ActiveRecord::SubclassNotFound for existing DB records
  # after the SlackSlashCommands integration was removed.
  # TODO: Remove this file after the cleanup migration has run.
  class SlackSlashCommands < Integration
    def self.title
      'Slack slash commands'
    end

    def self.description
      'Perform common operations in Slack.'
    end

    def self.to_param
      'slack_slash_commands'
    end
  end
end
