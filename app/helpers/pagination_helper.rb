module PaginationHelper
  def paginate_collection(collection, remote: nil)
    if collection.is_a?(Kaminari::PaginatableWithoutCount)
      paginate_without_count(collection)
    elsif collection.respond_to?(:total_pages)
      paginate_with_count(collection, remote: remote)
    end
  end

  def paginate_without_count(collection)
    render(
      'kaminari/gitlab/without_count',
      previous_path: path_to_prev_page(collection),
      next_path: path_to_next_page(collection)
    )
  end

  def paginate_with_count(collection, remote: nil)
    paginate(collection, remote: remote, theme: 'gitlab')
  end
end
