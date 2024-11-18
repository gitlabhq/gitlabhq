# frozen_string_literal: true

module Notes
  class QuickActionsStatus
    attr_accessor :messages, :error_messages, :commands_only, :command_names

    def initialize(command_names:, commands_only:)
      @command_names = command_names
      @commands_only = commands_only
      @messages = []
      @error_messages = []
    end

    def add_message(message)
      @messages.append(message) unless message.blank?
    end

    def add_error(message)
      @error_messages.append(message)
    end

    def commands_only?
      commands_only
    end

    def success?
      !error?
    end

    def error?
      error_messages.any?
    end

    def to_h
      payload = {
        command_names: command_names,
        commands_only: commands_only
      }

      payload[:messages] = messages.presence
      payload[:error_messages] = error_messages if error_messages.any?
      payload
    end
  end
end
