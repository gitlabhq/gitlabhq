# frozen_string_literal: true

module Gitlab
  module Repositories
    class Identifier
      include Gitlab::Utils::StrongMemoize

      InvalidIdentifier = Class.new(ArgumentError)

      def self.parse(gl_repository)
        segments = gl_repository&.split('-')

        # gl_repository can either have 2 or 3 segments:
        #
        # TODO: convert all 2-segment format to 3-segment:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/219192
        identifier = case segments&.size
                     when 2
                       TwoPartIdentifier.new(*segments)
                     when 3
                       ThreePartIdentifier.new(*segments)
                     end

        return identifier if identifier&.valid?

        raise InvalidIdentifier, %(Invalid GL Repository "#{gl_repository}")
      end

      # The older 2-segment format, where the container is implied.
      # eg. project-1, wiki-1
      class TwoPartIdentifier < Identifier
        def initialize(repo_type_name, container_id_str)
          @container_id_str = container_id_str
          @repo_type_name = repo_type_name
        end

        private

        def container_class
          repo_type.container_class
        end
      end

      # The newer 3-segment format, where the container is explicit
      # eg. group-1-wiki, project-1-wiki
      class ThreePartIdentifier < Identifier
        def initialize(container_type, container_id_str, repo_type_name)
          @container_id_str = container_id_str
          @container_type = container_type
          @repo_type_name = repo_type_name
        end

        private

        def container_class
          # NOTE: This is currently only used and supported for group wikis
          # https://gitlab.com/gitlab-org/gitlab/-/issues/219192
          return unless @repo_type_name == 'wiki'

          "#{@container_type}_#{@repo_type_name}".classify.constantize
        rescue NameError
          nil
        end
      end

      def repo_type
        Gitlab::GlRepository.types[repo_type_name]
      end
      strong_memoize_attr :repo_type

      def container
        container_class.find_by_id(container_id)
      end
      strong_memoize_attr :container

      def valid?
        repo_type.present? && container_class.present? && container_id&.positive?
      end

      private

      attr_reader :container_id_str, :repo_type_name

      def container_id
        Integer(container_id_str, 10, exception: false)
      end
      strong_memoize_attr :container_id
    end
  end
end
