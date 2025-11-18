# frozen_string_literal: true

class TagsFinder < GitRefsFinder
  def execute(gitaly_pagination: false, batch_load_signatures: false)
    tags = if gitaly_pagination && search.blank?
             repository.tags_sorted_by(sort, pagination_params)
           else
             repository.tags_sorted_by(sort)
           end

    by_search(tags).tap do |records|
      batch_load_tag_signature_data(records) if batch_load_signatures
      set_next_cursor(records) if gitaly_pagination
    end
  rescue ArgumentError => e
    raise Gitlab::Git::InvalidPageToken, "Invalid page token: #{page_token}" if e.message.include?('page token')

    raise
  end

  def total
    repository.tag_count
  end

  private

  def batch_load_tag_signature_data(tags)
    # Call methods on the tag that will allow BatchLoader to load signature data in batches
    tags.each do |t|
      if t.can_use_lazy_cached_signature?
        t.lazy_cached_signature
      else
        t.signed_tag&.signature_data
      end
    end
  end

  def page_token
    "#{Gitlab::Git::TAG_REF_PREFIX}#{@params[:page_token]}" if params[:page_token]
  end
end
