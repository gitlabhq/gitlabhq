# frozen_string_literal: true

module Ci
  module Catalog
    # This class is the SSoT to displaying the list of resources in the CI/CD Catalog.
    class Listing
      MIN_SEARCH_LENGTH = 3

      def initialize(current_user)
        @current_user = current_user
      end

      def resources(sort: nil, search: nil, scope: :all, verification_level: nil)
        relation = Ci::Catalog::Resource.published.includes(:project)
        relation = by_scope(relation, scope)
        relation = by_search(relation, search)
        relation = by_verification_level(relation, verification_level)

        case sort.to_s
        when 'name_desc' then relation.order_by_name_desc
        when 'name_asc' then relation.order_by_name_asc
        when 'latest_released_at_desc' then relation.order_by_latest_released_at_desc
        when 'latest_released_at_asc' then relation.order_by_latest_released_at_asc
        when 'created_at_asc' then relation.order_by_created_at_asc
        when 'created_at_desc' then relation.order_by_created_at_desc
        when 'usage_count_asc' then relation.order_by_last_30_day_usage_count_asc
        when 'usage_count_desc' then relation.order_by_last_30_day_usage_count_desc
        when 'star_count_asc' then relation.order_by_star_count(:asc)
        else
          relation.order_by_star_count(:desc)
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

      def by_search(relation, search)
        return relation unless search
        return relation.none if search.length < MIN_SEARCH_LENGTH

        relation.search(search)
      end

      def by_scope(relation, scope)
        if scope == :namespaces
          relation.visible_to_user(current_user)
        else
          relation.public_or_visible_to_user(current_user)
        end
      end

      def by_verification_level(relation, level)
        return relation unless level

        relation.for_verification_level(level)
      end
    end
  end
end
