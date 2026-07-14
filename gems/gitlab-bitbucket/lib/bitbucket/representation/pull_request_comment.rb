# frozen_string_literal: true

module Bitbucket
  module Representation
    class PullRequestComment < Comment
      def iid
        raw['id']
      end

      def file_path
        inline.fetch('path')
      end

      def old_pos
        inline.fetch('from')
      end

      def new_pos
        inline.fetch('to')
      end

      def parent_id
        raw.fetch('parent', {}).fetch('id', nil)
      end

      def inline?
        raw.key?('inline')
      end

      def has_parent?
        raw.key?('parent')
      end

      def deleted?
        raw.fetch('deleted', false)
      end

      private

      def inline
        raw.fetch('inline', {})
      end
    end
  end
end
