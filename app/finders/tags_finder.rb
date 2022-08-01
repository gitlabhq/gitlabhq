# frozen_string_literal: true

class TagsFinder < GitRefsFinder
  def execute(gitaly_pagination: false)
    tags = if gitaly_pagination && search.blank?
             repository.tags_sorted_by(sort, pagination_params)
           else
             repository.tags_sorted_by(sort)
           end

    by_search(tags)

  rescue ArgumentError => e
    raise Gitlab::Git::InvalidPageToken, "Invalid page token: #{page_token}" if e.message.include?('page token')

    raise
  end

  def total
    repository.tag_count
  end

  private

  def per_page
    params[:per_page].presence
  end

  def page_token
    "#{Gitlab::Git::TAG_REF_PREFIX}#{@params[:page_token]}" if params[:page_token]
  end

  def pagination_params
    { limit: per_page, page_token: page_token }
  end
end
