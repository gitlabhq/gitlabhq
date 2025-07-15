# frozen_string_literal: true

module RapidDiffs
  class BasePresenter < Gitlab::View::Presenter::Delegated
    def initialize(subject, diff_view, diff_options, request_params = nil)
      super(subject)
      @diff_view = diff_view
      @diff_options = diff_options
      @request_params = request_params
    end

    def diffs_stream_url
      return reload_stream_url(diff_view: @diff_view) if offset == 0
      return if offset.nil? || offset >= diffs_count

      reload_stream_url(offset: offset, diff_view: @diff_view)
    end

    def reload_stream_url(offset: nil, diff_view: nil)
      raise NotImplementedError
    end

    def diffs_slice
      return if offset.nil? || offset == 0

      @diffs_slice ||= resource.first_diffs_slice(offset, @diff_options)
    end

    def diffs_stats_endpoint
      raise NotImplementedError
    end

    def diff_files_endpoint
      raise NotImplementedError
    end

    def diff_file_endpoint
      raise NotImplementedError
    end

    def should_sort_metadata_files?
      false
    end

    def lazy?
      offset.nil?
    end

    protected

    attr_reader :request_params

    def offset
      5
    end

    private

    def diffs_count
      @diffs_count ||= resource.diffs_for_streaming.diff_files.count
    end
  end
end
