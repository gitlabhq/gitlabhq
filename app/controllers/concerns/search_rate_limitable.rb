# frozen_string_literal: true

module SearchRateLimitable
  extend ActiveSupport::Concern

  private

  def check_search_rate_limit!
    if current_user
      check_rate_limit!(:search_rate_limit, scope: [current_user])
    else
      check_rate_limit!(:search_rate_limit_unauthenticated, scope: [request.ip])
    end
  end
end
