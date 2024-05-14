# frozen_string_literal: true

module HotlinkInterceptor
  extend ActiveSupport::Concern

  def intercept_hotlinking!
    render_406 if Gitlab::HotlinkingDetector.intercept_hotlinking?(request)
  end

  private

  def render_406
    head :not_acceptable
  end
end
