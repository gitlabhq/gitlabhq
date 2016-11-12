module Mattermost
  module Commands
    class BaseService < ::BaseService
      class << self
        def triggered_by?(_)
          raise NotImplementedError
        end

        def available?(_)
          raise NotImplementedError
        end

        def help_message(_)
          NotImplementedError
        end
      end

      QUERY_LIMIT = 5

      def execute
        subcommand, args = parse_command

        if subcommands.include?(subcommand)
          send(subcommand, args)
        else
          nil
        end
      end

      private

      # This method can only be used by a resource that has an iid. Also, the
      # class should implement #collection itself. Probably project.resource
      # would suffice
      def show(args)
        iid = args.first

        result = collection.find_by(iid: iid)
        if readable?(result)
          result
        else
          nil
        end
      end

      # Child class should implement #collection
      def search(args)
        query = args.join(' ')

        collection.search(query).limit(QUERY_LIMIT).select do |issuable|
          readable?(issuable)
        end
      end

      def command
        params[:text]
      end
    end
  end
end
