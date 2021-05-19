# frozen_string_literal: true

# Include this in your controller and call `limit_pages` in order
# to configure the limiter.
#
#   Examples:
#     class MyController < ApplicationController
#       include PageLimiter
#
#       before_action only: [:index] do
#         limit_pages(500)
#       end
#
#       # You can override the default response
#       rescue_from PageOutOfBoundsError, with: :page_out_of_bounds
#
#       def page_out_of_bounds(error)
#         # Page limit number is available as error.message
#         head :ok
#       end
#

module PageLimiter
  extend ActiveSupport::Concern

  PageLimiterError          = Class.new(StandardError)
  PageLimitNotANumberError  = Class.new(PageLimiterError)
  PageLimitNotSensibleError = Class.new(PageLimiterError)
  PageOutOfBoundsError      = Class.new(PageLimiterError)

  included do
    rescue_from PageOutOfBoundsError, with: :default_page_out_of_bounds_response
  end

  def limit_pages(max_page_number)
    check_page_number!(max_page_number)
  end

  private

  # If the page exceeds the defined maximum, raise a PageOutOfBoundsError
  # If the page doesn't exceed the limit, it does nothing.
  def check_page_number!(max_page_number)
    raise PageLimitNotANumberError unless max_page_number.is_a?(Integer)
    raise PageLimitNotSensibleError unless max_page_number > 0

    if params[:page].present? && params[:page].to_i > max_page_number
      record_page_limit_interception
      raise PageOutOfBoundsError, max_page_number
    end
  end

  # By default just return a HTTP status code and an empty response
  def default_page_out_of_bounds_response
    head :bad_request
  end

  # Record the page limit being hit in Prometheus
  def record_page_limit_interception
    dd = DeviceDetector.new(request.user_agent)

    Gitlab::Metrics.counter(:gitlab_page_out_of_bounds,
      controller: params[:controller],
      action: params[:action],
      bot: dd.bot?
    ).increment
  end
end
