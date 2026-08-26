# frozen_string_literal: true

module Search
  module ScopeHandlers
    class Groups < Base
      def self.scope_name
        'groups'
      end

      def self.available?(user)
        ::Feature.enabled?(:elasticsearch_group_search, user)
      end

      private

      def fetch_results(page:, per_page:, preload_method: nil) # rubocop:disable Lint/UnusedMethodArgument -- signature matches the Base contract overridden in EE
        finder_results.page(page).per(per_page)
      end

      def total_count
        finder_results.limit(COUNT_LIMIT).count
      end

      def finder_results
        @finder_results ||= ::GroupsFinder.new(current_user, finder_params).execute
      end

      def finder_params
        params = { search: query }
        params[:archived] = false unless filters.to_h[:include_archived]

        if searched_group
          params.merge!(parent: searched_group, include_parent_descendants: true, include_ancestors: false)
        end

        params
      end

      def searched_group
        search_results.try(:group)
      end
    end
  end
end

Search::ScopeHandlers::Groups.prepend_mod
