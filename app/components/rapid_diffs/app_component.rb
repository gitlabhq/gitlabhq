# frozen_string_literal: true

module RapidDiffs
  class AppComponent < ViewComponent::Base
    renders_one :empty_state
    renders_one :before_diffs_list
    renders_one :diffs_list
    renders_one :after_diffs_list

    attr_reader :presenter

    delegate :diffs_stream_url, :reload_stream_url, :diffs_stats_endpoint, :diff_files_endpoint, :diff_file_endpoint,
      :sorted?, :diffs_slice, :lazy?, :environment, :linked_file, :diff_collection, :empty_state_type, to: :presenter

    delegate :diff_view, to: :helpers

    def initialize(presenter, extra_app_data: nil, extra_prefetch_endpoints: [])
      @presenter = presenter
      @extra_app_data = extra_app_data
      @extra_prefetch_endpoints = extra_prefetch_endpoints
    end

    def parallel_view?
      diff_view == :parallel
    end

    protected

    def app_data
      {
        diffs_stream_url: diffs_stream_url,
        reload_stream_url: reload_stream_url,
        diffs_stats_endpoint: diffs_stats_endpoint,
        diff_files_endpoint: diff_files_endpoint,
        should_sort_metadata_files: sorted?,
        show_whitespace: show_whitespace?,
        diff_view_type: diff_view,
        diff_file_endpoint: diff_file_endpoint,
        update_user_endpoint: update_user_endpoint,
        linked_file_data: linked_file_data,
        lazy: lazy?,
        file_by_file_mode: file_by_file_mode?
      }.merge(@extra_app_data || {})
    end

    def linked_file_data
      return unless linked_file

      {
        old_path: linked_file.old_path,
        new_path: linked_file.new_path
      }
    end

    def prefetch_endpoints
      [diffs_stats_endpoint, diff_files_endpoint, *@extra_prefetch_endpoints]
    end

    def update_user_endpoint
      helpers.expose_path(helpers.api_v4_user_preferences_path)
    end

    def show_whitespace?
      !helpers.hide_whitespace?
    end

    def file_by_file_mode?
      !!helpers.current_user&.view_diffs_file_by_file
    end

    def empty_state_visible?
      !lazy? && (empty_state? || empty_state_type)
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
