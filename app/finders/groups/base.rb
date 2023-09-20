# frozen_string_literal: true

module Groups
  class Base
    private

    def sort(items)
      items.reorder(Group.arel_table[:path].asc, Group.arel_table[:id].asc) # rubocop: disable CodeReuse/ActiveRecord
    end

    def by_search(items, exact_matches_first: false)
      return items if params[:search].blank?

      items.search(params[:search], include_parents: true, exact_matches_first: exact_matches_first)
    end
  end
end
