# frozen_string_literal: true

module PaginatedCollection
  extend ActiveSupport::Concern

  private

  def redirect_out_of_range(collection, total_pages = collection.total_pages)
    return false if total_pages.zero?

    out_of_range = collection.current_page > total_pages

    if out_of_range
      redirect_to(url_for(safe_params.merge(page: total_pages, only_path: true)))
    end

    out_of_range
  end
end
