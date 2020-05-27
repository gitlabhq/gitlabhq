# frozen_string_literal: true

module Gitlab
  class GlRepository
    class Identifier
      attr_reader :gl_repository, :repo_type

      def initialize(gl_repository)
        @gl_repository = gl_repository
        @segments = gl_repository.split('-')

        raise_error if segments.size > 3

        @repo_type = find_repo_type
        @container_id = find_container_id
        @container_class = find_container_class
      end

      def fetch_container!
        container_class.find_by_id(container_id)
      end

      private

      attr_reader :segments, :container_class, :container_id

      def find_repo_type
        type_name = three_segments_format? ? segments.last : segments.first
        type = Gitlab::GlRepository.types[type_name]

        raise_error unless type

        type
      end

      def find_container_class
        if three_segments_format?
          case segments[0]
          when 'project'
            Project
          when 'group'
            Group
          else
            raise_error
          end
        else
          repo_type.container_class
        end
      end

      def find_container_id
        id = Integer(segments[1], 10, exception: false)

        raise_error unless id

        id
      end

      # gl_repository can either have 2 or 3 segments:
      # "wiki-1" is the older 2-segment format, where container is implied.
      # "group-1-wiki" is the newer 3-segment format, including container information.
      #
      # TODO: convert all 2-segment format to 3-segment:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/219192
      def three_segments_format?
        segments.size == 3
      end

      def raise_error
        raise ArgumentError, "Invalid GL Repository \"#{gl_repository}\""
      end
    end
  end
end
