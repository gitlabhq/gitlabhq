# frozen_string_literal: true

class TagsFinder < GitRefsFinder
  # PaginationParameter.limit is a signed int32 in Gitaly's proto/shared.proto.
  MAX_GITALY_PAGINATION_LIMIT = (2**31) - 1

  def self.batch_load_tag_signature_data(tags)
    # Call methods on the tag that will allow BatchLoader to load signature data in batches
    tags.each do |t|
      if t.can_use_lazy_cached_signature?
        t.lazy_cached_signature
      else
        t.signed_tag&.signature_data
      end
    end
  end

  def execute(gitaly_pagination: false)
    tags = if bounded_offset_page?
             bounded_offset_tags
           elsif gitaly_pagination && search.blank?
             repository.tags_sorted_by(sort, pagination_params)
           else
             repository.tags_sorted_by(sort)
           end

    by_search(tags).tap do |records|
      set_next_cursor(records) if gitaly_pagination
    end
  rescue ArgumentError => e
    raise Gitlab::Git::InvalidPageToken, "Invalid page token: #{page_token}" if e.message.include?('page token')

    raise
  end

  def total
    repository.tag_count
  end

  # The pager uses this contract to avoid slicing an already-selected page again.
  def bounded_offset_page?
    params.fetch(:bounded_tag_offset, false) && search.blank? && params[:pagination] != 'keyset' &&
      params[:page].present? && params[:page].to_i != 1
  end

  private

  def bounded_offset_tags
    page = [params[:page].to_i, 1].max
    limit = [page * offset_per_page, MAX_GITALY_PAGINATION_LIMIT].min

    repository.tags_sorted_by(sort, { limit: limit })[(page - 1) * offset_per_page, offset_per_page] || []
  end

  def offset_per_page
    per_page || Kaminari.config.default_per_page
  end

  def page_token
    "#{Gitlab::Git::TAG_REF_PREFIX}#{@params[:page_token]}" if params[:page_token]
  end
end
