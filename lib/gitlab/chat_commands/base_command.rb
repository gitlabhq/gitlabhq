module Gitlab
  module ChatCommands
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

      attr_accessor :project, :current_user, :params

      def initialize(project, user, params = {})
        @project, @current_user, @params = project, user, params.dup
      end

      private

      def find_by_iid(iid)
        resource = collection.find_by(iid: iid)

        readable?(resource) ? resource : nil
      end
    end
  end
end
