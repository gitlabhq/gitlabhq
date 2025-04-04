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
      diff_files_endpoint:,
      lazy: false
    )
      @diffs_slice = diffs_slice
      @reload_stream_url = reload_stream_url
      @stream_url = stream_url
      @show_whitespace = show_whitespace
      @diff_view = diff_view
      @update_user_endpoint = update_user_endpoint
      @metadata_endpoint = metadata_endpoint
      @diff_files_endpoint = diff_files_endpoint
      @lazy = lazy
    end

    def empty_diff?
      @diffs_slice.nil? || @diffs_slice.empty?
    end

    def browser_visible?
      helpers.cookies[:file_browser_visible] != 'false'
    end

    def initial_browser_width
      Integer(helpers.cookies[:mr_tree_list_width])
    rescue StandardError
      nil
    end

    def sidebar_style
      styles = []
      styles << "width: #{initial_browser_width}px;" if initial_browser_width
      styles << "display: none;" unless browser_visible?
      styles.join(' ')
    end
  end
end
