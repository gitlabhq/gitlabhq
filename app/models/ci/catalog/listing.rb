# frozen_string_literal: true

module Ci
  module Catalog
    class Listing
      # This class is the SSoT to displaying the list of resources in the
      # CI/CD Catalog given a namespace as a scope.
      # This model is not directly backed by a table and joins catalog resources
      # with projects to return relevant data.
      def initialize(namespace, current_user)
        raise ArgumentError, 'Namespace is not a root namespace' unless namespace.root?

        @namespace = namespace
        @current_user = current_user
      end

      def resources(sort: nil)
        case sort.to_s
        when 'name_desc' then all_resources.order_by_name_desc
        when 'name_asc' then all_resources.order_by_name_asc
        else
          all_resources.order_by_created_at_desc
        end
      end

      private

      attr_reader :namespace, :current_user

      def all_resources
        Ci::Catalog::Resource
          .joins(:project).includes(:project)
          .merge(projects_in_namespace_visible_to_user)
      end

      def projects_in_namespace_visible_to_user
        Project
          .in_namespace(namespace.self_and_descendant_ids)
          .public_or_visible_to_user(current_user, ::Gitlab::Access::DEVELOPER)
      end
    end
  end
end
