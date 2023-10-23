# frozen_string_literal: true

module Ci
  module Catalog
    class Listing
      # This class is the SSoT to displaying the list of resources in the CI/CD Catalog.
      # This model is not directly backed by a table and joins catalog resources
      # with projects to return relevant data.

      MIN_SEARCH_LENGTH = 3

      def initialize(current_user)
        @current_user = current_user
      end

      def resources(namespace: nil, sort: nil, search: nil)
        relation = all_resources(search)
        relation = by_namespace(relation, namespace)

        case sort.to_s
        when 'name_desc' then relation.order_by_name_desc
        when 'name_asc' then relation.order_by_name_asc
        when 'latest_released_at_desc' then relation.order_by_latest_released_at_desc
        when 'latest_released_at_asc' then relation.order_by_latest_released_at_asc
        else
          relation.order_by_created_at_desc
        end
      end

      private

      attr_reader :current_user

      def all_resources(search)
        Ci::Catalog::Resource.joins(:project).includes(:project)
          .merge(find_projects(search))
      end

      def by_namespace(relation, namespace)
        return relation unless namespace
        raise ArgumentError, 'Namespace is not a root namespace' unless namespace.root?

        relation.merge(Project.in_namespace(namespace.self_and_descendant_ids))
      end

      def find_projects(search)
        finder_params = {
          minimum_search_length: MIN_SEARCH_LENGTH,
          search: search
        }

        ProjectsFinder.new(params: finder_params, current_user: current_user).execute
      end
    end
  end
end
