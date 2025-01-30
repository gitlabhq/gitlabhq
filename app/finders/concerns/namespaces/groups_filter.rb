# frozen_string_literal: true

module Namespaces
  module GroupsFilter
    private

    def by_ids(items)
      ids = params[:ids]
      items = items.id_in(ids) if ids
      items
    end

    def top_level_only(groups)
      params[:top_level_only].present? ? groups.by_parent(nil) : groups
    end

    def by_search(groups)
      return groups unless params[:search].present?

      groups.search(params[:search], include_parents: params[:parent].blank?)
    end

    def skip_groups(groups)
      return groups unless params[:skip_groups].present?

      groups.id_not_in(params[:skip_groups])
    end

    def min_access_level?
      current_user && params[:min_access_level].present?
    end

    def sort(groups)
      return groups.order_id_desc unless params[:sort]

      groups.sort_by_attribute(params[:sort])
    end

    def by_visibility(groups)
      return groups unless params[:visibility]

      groups.by_visibility_level(params[:visibility])
    end

    def by_min_access_level(groups)
      return groups unless min_access_level?

      groups.by_min_access_level(current_user, params[:min_access_level])
    end

    def apply_filters(groups)
      by_search(groups)
      .then { |filtered_groups| by_min_access_level(filtered_groups) }
    end
  end
end
