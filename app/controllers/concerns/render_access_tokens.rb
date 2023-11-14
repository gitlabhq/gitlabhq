# frozen_string_literal: true

module RenderAccessTokens
  extend ActiveSupport::Concern

  def active_access_tokens
    tokens = finder(state: 'active', sort: 'expires_at_asc_id_desc').execute.preload_users

    if Feature.enabled?('access_token_pagination')
      tokens = tokens.page(page)
      add_pagination_headers(tokens)
    end

    represent(tokens)
  end

  def add_pagination_headers(relation)
    Gitlab::Pagination::OffsetHeaderBuilder.new(
      request_context: self,
      per_page: relation.limit_value,
      page: relation.current_page,
      next_page: relation.next_page,
      prev_page: relation.prev_page,
      total: relation.total_count,
      params: params.permit(:page, :per_page)
    ).execute
  end

  def page
    (params[:page] || 1).to_i
  end
end
