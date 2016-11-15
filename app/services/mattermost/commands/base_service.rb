module Mattermost
  module Commands
    class BaseService < ::BaseService
      QUERY_LIMIT = 5

      def execute
        raise NotImplementedError
      end

      def available?
        raise NotImplementedError
      end

      def collection
        raise NotImplementedError
      end

      private

      def find_by_iid(iid)
        resource = collection.find_by(iid: iid)

        readable?(resource) ? resource : nil
      end

      def search
        collection.search(query).limit(QUERY_LIMIT).select do |resource|
          readable?(resource)
        end
      end

      # params[:text] = issue search <search query>
      def query
        params[:text].split[2..-1].join(' ')
      end

      # params[:text] = 'mergerequest show 123'
      def iid
        params[:text].split[2]
      end
    end
  end
end
