# frozen_string_literal: true

module Gitlab
  module Repositories
    class ContainerClassMismatchError < StandardError
      def initialize(container_class, repo_type)
        @container_class = container_class
        @repo_type = repo_type
      end

      def message
        "Expected container class to be #{@repo_type.container_class} for " \
          "repo type #{@repo_type.name}, but found #{@container_class} instead."
      end
    end
  end
end
