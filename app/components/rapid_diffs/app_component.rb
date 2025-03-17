# frozen_string_literal: true

module RapidDiffs
  class AppComponent < ViewComponent::Base
    renders_one :diffs_list

    def initialize(
      diffs_slice:,
      reload_stream_url:,
      stream_url:,
      show_whitespace:,
      diff_view:,
      update_user_endpoint:,
      metadata_endpoint:,
      preload: true
    )
      @diffs_slice = diffs_slice
      @reload_stream_url = reload_stream_url
      @stream_url = stream_url
      @show_whitespace = show_whitespace
      @diff_view = diff_view
      @update_user_endpoint = update_user_endpoint
      @metadata_endpoint = metadata_endpoint
      @preload = preload
    end

    def initial_sidebar_width
      helpers.cookies[:mr_tree_list_width]
    end
  end
end
