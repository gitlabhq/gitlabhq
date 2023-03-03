# frozen_string_literal: true

module Ci
  module Catalog
    class Listing
      # This class is the SSoT to displaying the list of resources in the
      # CI/CD Catalog given a namespace as a scope.
      # This model is not directly backed by a table and joins catalog resources
      # with projects to return relevant data.
      def initialize(namespace)
        raise ArgumentError, 'Namespace is not a root namespace' unless namespace.root?

        @namespace = namespace
      end

      def resources
        Ci::Catalog::Resource
          .joins(:project).includes(:project)
          .merge(Project.in_namespace(namespace.self_and_descendant_ids))
      end

      private

      attr_reader :namespace
    end
  end
end
