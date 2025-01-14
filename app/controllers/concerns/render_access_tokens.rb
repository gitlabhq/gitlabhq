# frozen_string_literal: true

module RenderAccessTokens
  extend ActiveSupport::Concern

  def active_access_tokens
    tokens = finder(state: 'active', sort: 'expires_at_asc_id_desc').execute.preload_users
    size = tokens.size

    tokens = tokens.page(page)
    add_pagination_headers(tokens)

    [represent(tokens), size]
  end

  def inactive_access_tokens
    finder(state: 'inactive', sort: 'updated_at_desc').execute.preload_users
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
    (pagination_params[:page] || 1).to_i
  end

  def expiry_ics(tokens)
    cal = Icalendar::Calendar.new
    tokens.each do |token|
      cal.event do |event|
        event.dtstart = Icalendar::Values::Date.new(token[:expires_at].delete('-'))
        event.dtend = Icalendar::Values::Date.new(token[:expires_at].delete('-'))
        event.summary = "Token #{token[:name]} expires today"
      end
    end
    cal.to_ical
  end
end
