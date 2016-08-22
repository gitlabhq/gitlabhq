module Bitbucket
  module Representation
    class Comment < Representation::Base
      def author
        user.fetch('username', 'Anonymous')
      end

      def note
        raw.dig('content', 'raw')
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
