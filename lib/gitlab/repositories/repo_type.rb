# frozen_string_literal: true

module Gitlab
  module Repositories
    class RepoType
      def name
        raise NotImplementedError, 'Define a name in a RepoType subclass'
      end

      def access_checker_class
        raise NotImplementedError, 'Define an access_checker_class in a RepoType subclass'
      end

      def guest_read_ability
        raise NotImplementedError, 'Define a guest_read_ability in a RepoType subclass'
      end

      def suffix = nil

      def container_class
        raise NotImplementedError, 'Define a container_class in a RepoType subclass'
      end

      def type_id
        name.to_s
      end

      def identifier_for_container(container)
        "#{name}-#{container.id}"
      end

      def wiki?
        name == :wiki
      end

      def project?
        name == :project
      end

      def snippet?
        name == :snippet
      end

      def design?
        name == :design
      end

      def path_suffix
        suffix ? ".#{suffix}" : ''
      end

      def repository_for(container)
        check_container(container)
        return unless container

        repository_resolver(container)
      end

      def project_for(container)
        raise NotImplementedError, 'Define a project_for in a RepoType subclass'
      end

      def valid?(repository_path)
        repository_path.end_with?(path_suffix) &&
          (
            !snippet? ||
            repository_path.match?(Gitlab::PathRegex.full_snippets_repository_path_regex)
          )
      end

      private

      def repository_resolver(container)
        raise NotImplementedError, 'Define a repository_resolver in a RepoType subclass'
      end

      def check_container(container)
        return unless container.present? && container_class.present?
        return if container.is_a?(container_class)

        raise ContainerClassMismatchError.new(container.class.name, self)
      end
    end
  end
end

Gitlab::Repositories::RepoType.prepend_mod_with('Gitlab::Repositories::RepoType')
