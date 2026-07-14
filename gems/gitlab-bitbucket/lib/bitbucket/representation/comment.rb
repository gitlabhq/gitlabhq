# frozen_string_literal: true

module Bitbucket
  module Representation
    class Comment < Representation::Base
      def author
        user['uuid']
      end

      def author_nickname
        user['nickname']
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
