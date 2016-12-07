module Bitbucket
  module Representation
    class PullRequestComment < Comment
      def iid
        raw['id']
      end

      def file_path
        inline.fetch('path', nil)
      end

      def old_pos
        inline.fetch('from', nil)
      end

      def new_pos
        inline.fetch('to', nil)
      end

      def parent_id
        raw.dig('parent', 'id')
      end

      def inline?
        raw.has_key?('inline')
      end

      def has_parent?
        raw.has_key?('parent')
      end

      private

      def inline
        raw.fetch('inline', {})
      end
    end
  end
end
