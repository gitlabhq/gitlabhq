# frozen_string_literal: true

module RapidDiffs
  module StreamingResource
    extend ActiveSupport::Concern
    include ActionController::Live
    include DiffHelper

    def diffs_stream
      streaming_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      stream_headers

      offset = { offset_index: params.permit(:offset)[:offset].to_i }

      context = view_context

      # view_context calls are not memoized, with explicit passing we are able to reuse it across renders
      stream_diff_files(streaming_diff_options.merge(offset), context)

      streaming_time = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - streaming_start_time).round(2)
      response.stream.write "<server-timings streaming=\"#{streaming_time}\"></server-timings>"
    rescue ActionController::Live::ClientDisconnected, IOError
      # Ignored
    rescue StandardError => e
      Gitlab::AppLogger.error("Error streaming diffs: #{e.message}")
      error_component = ::RapidDiffs::StreamingErrorComponent.new(message: e.message)
      response.stream.write error_component.render_in(context)
    ensure
      response.stream.close unless response.stream.closed?
    end

    def request
      # We only need to do this in rapid diffs streaming endpoints
      # as calling `request.format` (which can happen when rendering view components
      # but can possibly happen in other places as well) can raise an exception
      # while streaming diffs.
      Request.new(super)
    end

    private

    def streaming_diff_options
      diff_options
    end

    def view
      helpers.diff_view
    end

    def stream_diff_files(options, view_context)
      return unless rapid_diffs_presenter

      # NOTE: This is a temporary flag to test out the new diff_blobs
      use_new_gitaly_rpc = ActiveModel::Type::Boolean.new.cast(params.permit(:diff_blobs)[:diff_blobs])
      if use_new_gitaly_rpc && Feature.enabled?(:rapid_diffs_debug, current_user)
        stream_diff_blobs(options, view_context)
      else
        stream_diff_collection(options, view_context)
      end
    end

    def stream_diff_collection(options, view_context)
      diff_files = rapid_diffs_presenter.diff_files_for_streaming(options)

      return render_empty_state if diff_files.empty?

      old_path = params.permit(:skip_old_path)[:skip_old_path]
      new_path = params.permit(:skip_new_path)[:skip_new_path]

      skipped = []
      diff_files.each do |diff_file|
        next if old_path && new_path && diff_file.old_path == old_path && diff_file.new_path == new_path

        if diff_file.no_preview?
          skipped << diff_file
        else
          unless skipped.empty?
            response.stream.write(diff_files_collection(skipped).render_in(view_context))
            skipped = []
          end

          response.stream.write(diff_file_component(diff_file).render_in(view_context))
        end
      end

      response.stream.write(diff_files_collection(skipped).render_in(view_context)) unless skipped.empty?
    end

    attr_reader :environment

    def diff_file_component(diff_file)
      ::RapidDiffs::DiffFileComponent.new(
        diff_file: diff_file,
        parallel_view: view == :parallel,
        environment: environment)
    end

    def diff_files_collection(diff_files)
      ::RapidDiffs::DiffFileComponent.with_collection(
        diff_files,
        parallel_view: view == :parallel,
        environment: environment)
    end

    def stream_diff_blobs(options, view_context)
      return render_empty_state if rapid_diffs_presenter.diff_files_for_streaming(options).count == 0

      rapid_diffs_presenter.diff_files_for_streaming_by_changed_paths(options) do |diff_files_batch|
        response.stream.write(diff_files_collection(diff_files_batch).render_in(view_context))
      end
    end

    def render_empty_state
      response.stream.write render ::RapidDiffs::EmptyStateComponent.new, layout: false
    end

    class Request < SimpleDelegator
      def format
        Mime::Type.lookup("text/html")
      end
    end
  end
end
