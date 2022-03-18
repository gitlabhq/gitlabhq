# frozen_string_literal: true

module PaginationHelper
  # total_pages will be inferred from the collection if nil. It is ignored if
  # the collection is a Kaminari::PaginatableWithoutCount
  def paginate_collection(collection, remote: nil, total_pages: nil)
    if collection.is_a?(Kaminari::PaginatableWithoutCount)
      paginate_without_count(collection)
    elsif collection.respond_to?(:total_pages)
      paginate_with_count(collection, remote: remote, total_pages: total_pages)
    end
  end

  def paginate_without_count(collection)
    render(
      'kaminari/gitlab/without_count',
      previous_path: path_to_prev_page(collection),
      next_path: path_to_next_page(collection)
    )
  end

  def paginate_with_count(collection, remote: nil, total_pages: nil)
    paginate(collection, remote: remote, theme: 'gitlab', total_pages: total_pages)
  end

  def page_size
    Kaminari.config.default_per_page
  end
end
