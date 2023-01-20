# frozen_string_literal: true

module Groups
  class Base
    private

    def sort(items)
      items.reorder(Group.arel_table[:path].asc, Group.arel_table[:id].asc) # rubocop: disable CodeReuse/ActiveRecord
    end

    def by_search(items)
      return items if params[:search].blank?

      items.search(params[:search], include_parents: true)
    end
  end
end
