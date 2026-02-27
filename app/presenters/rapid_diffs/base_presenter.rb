# frozen_string_literal: true

module RapidDiffs
  class BasePresenter < Gitlab::View::Presenter::Delegated
    def initialize(subject, diff_view:, diff_options:, current_user: nil, request_params: nil, environment: nil)
      super(subject)
      @diff_view = diff_view
      @diff_options = diff_options
      @current_user = current_user
      @request_params = request_params
      @environment = environment
    end

    attr_reader :environment

    def diffs_resource(options = {})
      resource.diffs(@diff_options.merge(options))
    end

    def diff_files(options = {})
      transform_file_collection(diffs_resource(options).diff_files(sorted: sorted?))
    end

    def diffs_slice
      return if offset.nil? || offset == 0

      @diffs_slice ||= transform_file_collection(resource.first_diffs_slice(offset, @diff_options))
    end

    def diff_files_for_streaming(diff_options = {})
      transform_file_collection(resource.diffs_for_streaming(diff_options).diff_files(sorted: sorted?))
    end

    def diff_files_for_streaming_by_changed_paths(diff_options = {})
      resource.diffs_for_streaming_by_changed_paths(diff_options) do |diff_files|
        yield transform_file_array(diff_files) if block_given?
      end
    end

    def linked_file
      return if lazy? || (linked_file_params[:old_path].nil? && linked_file_params[:new_path].nil?)

      @linked_file ||= resource.diffs(@diff_options.merge({
        paths: [linked_file_params[:old_path], linked_file_params[:new_path]].compact
      })).diff_files.first.then do |file|
        next unless file

        file.linked = true
        transform_file(file)
      end
    end

    def diffs_stream_url
      return if linked_file && diffs_count == 1

      if linked_file
        return reload_stream_url(
          offset: nil,
          diff_view: @diff_view,
          skip_old_path: linked_file_params[:old_path],
          skip_new_path: linked_file_params[:new_path]
        )
      end

      return reload_stream_url(diff_view: @diff_view) if offset == 0
      return if offset.nil? || offset >= diffs_count

      reload_stream_url(
        offset: offset,
        diff_view: @diff_view
      )
    end

    def reload_stream_url(offset: nil, diff_view: nil, skip_old_path: nil, skip_new_path: nil)
      raise NotImplementedError
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

    def sorted?
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

    def transform_file(diff_file)
      diff_file.prevent_syntax_highlighting! unless highlight?
      diff_file
    end

    private

    def highlight?
      return @highlight if defined?(@highlight)

      @highlight = @current_user.nil? || Gitlab::ColorSchemes.for_user(@current_user).css_class != 'none'
    end

    def transform_file_collection(diff_files)
      diff_files.decorate! { |file| transform_file(file) }
      diff_files
    end

    def transform_file_array(diff_files)
      diff_files.map { |file| transform_file(file) }
    end

    def diffs_count
      @diffs_count ||= begin
        count = resource.diff_stats&.count
        count || resource.diffs_for_streaming.diff_files.count
      end
    end

    def linked_file_params
      {
        old_path: request_params[:old_path] || request_params[:file_path],
        new_path: request_params[:new_path] || request_params[:file_path]
      }
    end
  end
end
