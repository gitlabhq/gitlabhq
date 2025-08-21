# frozen_string_literal: true

module PaginatedCollection
  extend ActiveSupport::Concern

  private

  def redirect_out_of_range(collection, total_pages = collection.total_pages)
    return false if total_pages == 0

    out_of_range = collection.current_page > total_pages

    redirect_to(url_for(safe_params.merge(page: total_pages, only_path: true))) if out_of_range

    out_of_range
  end

  def paginate_for_collection(collection, row_count:)
    row_count = request.format.atom? ? -1 : row_count

    paginated = collection.page(params[:page])

    # manual / relative_position sorting allows for 100 items on the page
    paginated = paginated.per(100) if params[:sort] == 'relative_position'
    paginated = paginated.without_count if row_count == -1

    {
      collection: paginated,
      total_pages: page_count_for_relation(paginated, row_count)
    }
  end

  def page_count_for_relation(relation, row_count)
    limit = relation.limit_value.to_f

    return 1 if limit == 0
    return (params[:page] || 1).to_i + 1 if row_count == -1

    (row_count.to_f / limit).ceil
  end
end
