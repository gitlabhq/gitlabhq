# frozen_string_literal: true

module Bitbucket
  module Representation
    class Issue < Representation::Base
      CLOSED_STATUS = %w[resolved invalid duplicate wontfix closed].freeze

      def iid
        raw['id']
      end

      def kind
        raw['kind']
      end

      def author
        raw.dig('reporter', 'uuid')
      end

      def author_nickname
        raw.dig('reporter', 'nickname')
      end

      def description
        raw.fetch('content', {}).fetch('raw', nil)
      end

      def state
        closed? ? 'closed' : 'opened'
      end

      def title
        raw['title']
      end

      def milestone
        raw['milestone']['name'] if raw['milestone'].present?
      end

      def created_at
        raw['created_on']
      end

      def updated_at
        raw['edited_on']
      end

      def to_s
        iid
      end

      def to_hash
        {
          iid: iid,
          title: title,
          description: description,
          state: state,
          author: author,
          author_nickname: author_nickname,
          milestone: milestone,
          created_at: created_at,
          updated_at: updated_at
        }
      end

      private

      def closed?
        CLOSED_STATUS.include?(raw['state'])
      end
    end
  end
end
