module Gitlab
  module ChatCommands
    class BaseCommand
      QUERY_LIMIT = 5

      def self.match(_)
        raise NotImplementedError
      end

      def self.help_message
        raise NotImplementedError
      end

      def self.available?(_)
        raise NotImplementedError
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

      def can?(object, action, subject)
        Ability.allowed?(object, action, subject)
      end

      def find_by_iid(iid)
        resource = collection.find_by(iid: iid)

        readable?(resource) ? resource : nil
      end

      def search_results(query)
        collection.search(query).limit(QUERY_LIMIT).select do |resource|
          readable?(resource)
        end
      end
    end
  end
end
