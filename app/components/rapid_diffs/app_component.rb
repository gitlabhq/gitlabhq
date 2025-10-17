# frozen_string_literal: true

module RapidDiffs
  class AppComponent < ViewComponent::Base
    renders_one :diffs_list

    attr_reader :presenter

    delegate :diffs_stream_url, :reload_stream_url, :diffs_stats_endpoint, :diff_files_endpoint, :diff_file_endpoint,
      :should_sort_metadata_files?, :diffs_slice, :lazy?, to: :presenter

    delegate :diff_view, :current_user, to: :helpers

    def initialize(presenter)
      @presenter = presenter
    end

    protected

    def app_data
      {
        diffs_stream_url: diffs_stream_url,
        reload_stream_url: reload_stream_url,
        diffs_stats_endpoint: diffs_stats_endpoint,
        diff_files_endpoint: diff_files_endpoint,
        should_sort_metadata_files: should_sort_metadata_files?,
        show_whitespace: show_whitespace?,
        diff_view_type: diff_view,
        diff_file_endpoint: diff_file_endpoint,
        update_user_endpoint: update_user_endpoint,
        lazy: lazy?
      }
    end

    def prefetch_endpoints
      [diffs_stats_endpoint, diff_files_endpoint]
    end

    def update_user_endpoint
      helpers.expose_path(helpers.api_v4_user_preferences_path)
    end

    def show_whitespace?
      !helpers.hide_whitespace?
    end

    def parallel_view?
      diff_view == :parallel
    end

    def empty_state_visible?
      !diffs_stream_url && !lazy? && (diffs_slice.nil? || diffs_slice.empty?)
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
