module Bitbucket
  module Representation
    class Comment < Representation::Base
      def author
        user['username']
      end

      def note
        raw.fetch('content', {}).fetch('raw', nil)
      end

      def created_at
        raw['created_on']
      end

      def updated_at
        raw['updated_on'] || raw['created_on']
      end

      private

      def user
        raw.fetch('user', {})
      end
    end
  end
end
