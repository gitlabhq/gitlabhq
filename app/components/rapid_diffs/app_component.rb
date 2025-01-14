# frozen_string_literal: true

module RapidDiffs
  class AppComponent < ViewComponent::Base
    def initialize(diffs_slice:, reload_stream_url:, stream_url:, show_whitespace:, diff_view:, update_user_endpoint:)
      @diffs_slice = diffs_slice
      @reload_stream_url = reload_stream_url
      @stream_url = stream_url
      @show_whitespace = show_whitespace
      @diff_view = diff_view
      @update_user_endpoint = update_user_endpoint
    end
  end
end
