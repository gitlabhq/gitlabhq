# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class BaseCommand
      QUERY_LIMIT = 5

      def self.match(_text)
        raise NotImplementedError
      end

      def self.help_message
        raise NotImplementedError
      end

      def self.available?(_project)
        raise NotImplementedError
      end

      def self.allowed?(_user, _ability)
        true
      end

      def self.can?(object, action, subject)
        Ability.allowed?(object, action, subject)
      end

      def execute(_)
        raise NotImplementedError
      end

      def collection
        raise NotImplementedError
      end

      attr_accessor :project, :current_user, :params, :chat_name

      def initialize(project, chat_name, params = {})
        @project = project
        @current_user = chat_name.user
        @params = params.dup
        @chat_name = chat_name
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def find_by_iid(iid)
        collection.find_by(iid: iid)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
