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
      resource.diffs(diff_options.merge(options))
    end

    def diff_files(options = {})
      transform_file_collection(diffs_resource(options))
    end

    def diffs_slice
      return unless loaded_diffs_slice

      @diffs_slice ||= transform_file_collection(loaded_diffs_slice)
    end

    def diff_files_for_streaming(diff_options = {})
      # Duplicate `diff_options` so in case it gets mutated during the rest of
      # code path, it won't affect other callers of that `diff_options`.
      collection = resource.diffs_for_streaming(diff_options.dup)
      with_linked_file_first(transform_file_collection(collection))
    end

    def diff_files_for_streaming_by_changed_paths(diff_options = {})
      # Duplicate `diff_options` so in case it gets mutated during the rest of
      # code path, it won't affect other callers of that `diff_options`.
      resource.diffs_for_streaming_by_changed_paths(diff_options.dup) do |diff_files|
        yield transform_file_array(diff_files) if block_given?
      end
    end

    def linked_file
      return if linked_file_params[:old_path].nil? && linked_file_params[:new_path].nil?

      @linked_file ||= begin
        collection = resource.diffs(diff_options.merge({
          paths: [linked_file_params[:old_path], linked_file_params[:new_path]].compact
        }))
        file = collection.diff_files.first

        if file
          file.linked = true
          transform_file_collection(collection).first
        end
      end
    end

    def diffs_stream_url
      return if linked_file && !has_overflow?

      if linked_file
        return reload_stream_url(
          offset: nil,
          diff_view: @diff_view,
          skip_old_path: linked_file_params[:old_path],
          skip_new_path: linked_file_params[:new_path]
        )
      end

      return reload_stream_url(diff_view: @diff_view) if offset == 0
      return if offset.nil? || !has_overflow?

      reload_stream_url(
        offset: stream_offset,
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

    def empty_state_type
      return unless loaded_diffs_slice

      :no_changes if loaded_diffs_slice.count == 0
    end

    def diff_collection
      return [linked_file] if linked_file

      result = diffs_slice || []
      file_by_file_mode? ? result.first(1) : result
    end

    def file_by_file_mode?
      !!@current_user&.view_diffs_file_by_file
    end

    attr_accessor :baseline_offset

    def offset
      return 1 if linked_file

      baseline_offset
    end

    protected

    attr_reader :request_params

    def transform_file_collection(collection)
      diff_files = collection.diff_files(sorted: sorted?)
      diff_files.decorate! { |file| transform_file(file) }
      diff_files
    end

    def transform_file(diff_file)
      diff_file.prevent_syntax_highlighting! unless highlight?
      linked_line_unfolder&.unfold!(diff_file) if diff_file.linked
      diff_file
    end

    def has_overflow?
      return false unless loaded_diffs_slice

      loaded_diffs_slice.overflow?
    end

    def stream_offset
      loaded_diffs_slice.count
    end

    def include_diff_stats?
      false
    end

    private

    def linked_line_unfolder
      return @linked_line_unfolder if defined?(@linked_line_unfolder)

      @linked_line_unfolder = Gitlab::Diff::LinkedLineUnfolder.from_param(request_params && request_params[:line])
    end

    def diff_options
      @diff_options.merge(include_stats: include_diff_stats?)
    end

    def loaded_diffs_slice
      return if offset.nil? || offset == 0

      @loaded_diffs_slice ||= resource.first_diffs_slice(offset, diff_options)
    end

    def highlight?
      return @highlight if defined?(@highlight)

      @highlight = @current_user.nil? || Gitlab::ColorSchemes.for_user(@current_user).css_class != 'none'
    end

    def transform_file_array(diff_files)
      diff_files.map { |file| transform_file(file) }
    end

    def linked_file_params
      {
        old_path: request_params[:old_path] || request_params[:file_path],
        new_path: request_params[:new_path] || request_params[:file_path]
      }
    end

    def with_linked_file_first(collection)
      old_path = linked_file_params[:old_path]
      new_path = linked_file_params[:new_path]
      return collection unless old_path && new_path

      result = []
      collection.each do |file|
        if file.old_path == old_path && file.new_path == new_path
          file.linked = true
          result.unshift(file)
        else
          result << file
        end
      end

      result
    end
  end
end
