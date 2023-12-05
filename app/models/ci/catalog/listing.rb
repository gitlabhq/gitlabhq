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

      def resources(namespace: nil, sort: nil, search: nil, scope: :all)
        relation = Ci::Catalog::Resource.published.joins(:project).includes(:project)
        relation = by_scope(relation, scope)
        relation = by_namespace(relation, namespace)
        relation = by_search(relation, search)

        case sort.to_s
        when 'name_desc' then relation.order_by_name_desc
        when 'name_asc' then relation.order_by_name_asc
        when 'latest_released_at_desc' then relation.order_by_latest_released_at_desc
        when 'latest_released_at_asc' then relation.order_by_latest_released_at_asc
        when 'created_at_asc' then relation.order_by_created_at_asc
        else
          relation.order_by_created_at_desc
        end
      end

      def find_resource(id: nil, full_path: nil)
        resource = id ? Ci::Catalog::Resource.find_by_id(id) : Project.find_by_full_path(full_path)&.catalog_resource

        return unless resource.present?
        return unless resource.published?
        return unless Ability.allowed?(current_user, :read_code, resource.project)

        resource
      end

      private

      attr_reader :current_user

      def by_namespace(relation, namespace)
        return relation unless namespace
        raise ArgumentError, 'Namespace is not a root namespace' unless namespace.root?

        relation.merge(Project.in_namespace(namespace.self_and_descendant_ids))
      end

      def by_search(relation, search)
        return relation unless search
        return relation.none if search.length < MIN_SEARCH_LENGTH

        relation.search(search)
      end

      def by_scope(relation, scope)
        if scope == :namespaces && Feature.enabled?(:ci_guard_for_catalog_resource_scope, current_user)
          relation.merge(Project.visible_to_user(current_user))
        else
          relation.merge(Project.public_or_visible_to_user(current_user))
        end
      end
    end
  end
end
