# frozen_string_literal: true

# Wikis::PageMetaFinder
#
# Used to filter WikiPage::Meta collections by set of params
#
# Arguments:
#   user - which user to scope visibility for
#   params:
#     search: string - filter by title (ILIKE match)
#
module Wikis
  class PageMetaFinder
    def initialize(user, search: nil, **)
      @user = user
      @search = search
    end

    def execute
      items = init_collection
      by_search(items)
    end

    # Required by RecentItems#query_items_by_ids to return a typed empty relation
    # when no recent item IDs are found.
    def klass
      WikiPage::Meta
    end

    private

    attr_reader :user, :search

    def init_collection
      WikiPage::Meta.from_union([
        WikiPage::Meta.active.for_projects_visible_to_user(user),
        WikiPage::Meta.active.for_groups_visible_to_user(user)
      ])
    end

    def by_search(items)
      return items unless search.present?

      items.search_by_title(search)
    end
  end
end
