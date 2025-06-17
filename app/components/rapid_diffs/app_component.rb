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
      diffs_stats_endpoint:,
      diff_files_endpoint:,
      diff_file_endpoint:,
      should_sort_metadata_files: false,
      lazy: false
    )
      @diffs_slice = diffs_slice
      @reload_stream_url = reload_stream_url
      @stream_url = stream_url
      @show_whitespace = show_whitespace
      @diff_view = diff_view
      @update_user_endpoint = update_user_endpoint
      @diffs_stats_endpoint = diffs_stats_endpoint
      @diff_files_endpoint = diff_files_endpoint
      @should_sort_metadata_files = should_sort_metadata_files
      @diff_file_endpoint = diff_file_endpoint
      @lazy = lazy
    end

    def app_data
      {
        diffs_stream_url: @stream_url,
        reload_stream_url: @reload_stream_url,
        diffs_stats_endpoint: @diffs_stats_endpoint,
        diff_files_endpoint: @diff_files_endpoint,
        should_sort_metadata_files: @should_sort_metadata_files,
        show_whitespace: @show_whitespace,
        diff_view_type: @diff_view,
        diff_file_endpoint: @diff_file_endpoint,
        update_user_endpoint: @update_user_endpoint
      }
    end

    def parallel_view?
      @diff_view == :parallel
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

    def root_label
      s_('RapidDiffs|Changes view')
    end

    def header_label
      s_('RapidDiffs|View controls')
    end

    def content_label
      s_('RapidDiffs|Diff files')
    end
  end
end
