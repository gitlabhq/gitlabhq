module KaminariPagination
  extend ActiveSupport::Concern

  def bounded_pagination(items, page_number)
    items = items.page(page_number)
    items.to_a.empty? ? items.page(items.total_pages) : items
  end
end
