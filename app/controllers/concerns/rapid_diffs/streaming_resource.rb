# frozen_string_literal: true

module RapidDiffs
  module StreamingResource
    extend ActiveSupport::Concern
    include ActionController::Live
    include DiffHelper

    def diffs
      return render_404 unless rapid_diffs_enabled?

      streaming_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      stream_headers

      offset = { offset_index: params.permit(:offset)[:offset].to_i }

      context = view_context

      # view_context calls are not memoized, with explicit passing we are able to reuse it across renders
      stream_diff_files(streaming_diff_options.merge(offset), context)

      streaming_time = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - streaming_start_time).round(2)
      response.stream.write "<server-timings streaming=\"#{streaming_time}\"></server-timings>"
    rescue ActionController::Live::ClientDisconnected
      # Ignored
    rescue StandardError => e
      Gitlab::AppLogger.error("Error streaming diffs: #{e.message}")
      error_component = ::RapidDiffs::StreamingErrorComponent.new(message: e.message)
      response.stream.write error_component.render_in(context)
    ensure
      response.stream.close
    end

    def request
      # We only need to do this in rapid diffs streaming endpoints
      # as calling `request.format` (which can happen when rendering view components
      # but can possibly happen in other places as well) can raise an exception
      # while streaming diffs.
      Request.new(super)
    end

    private

    def rapid_diffs_enabled?
      ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)
    end

    def resource
      raise NotImplementedError
    end

    def streaming_diff_options
      diff_options
    end

    def view
      helpers.diff_view
    end

    def stream_diff_files(options, view_context)
      return unless resource

      if params.permit(:offset)[:offset].blank? && resource.first_diffs_slice(1, options).empty?
        empty_state_component = ::RapidDiffs::EmptyStateComponent.new
        response.stream.write empty_state_component.render_in(view_context)
        return
      end

      # NOTE: This is a temporary flag to test out the new diff_blobs
      if !!ActiveModel::Type::Boolean.new.cast(params.permit(:diff_blobs)[:diff_blobs])
        stream_diff_blobs(options, view_context)
      else
        stream_diff_collection(options, view_context)
      end
    end

    def stream_diff_collection(options, view_context)
      diff_files = resource.diffs_for_streaming(options).diff_files(sorted: sorted?)

      each_growing_slice(diff_files, 5, 2) do |slice|
        response.stream.write(render_diff_files_collection(slice, view_context))
      end
    end

    def each_growing_slice(collection, initial_size, growth_factor = 2)
      position = 0
      size = initial_size
      total = collection.size

      while position < total
        yield collection.drop(position).first(size)

        position = [position + size, total].min
        size = (size * growth_factor).to_i
      end
    end

    def render_diff_files_collection(diff_files, view_context)
      ::RapidDiffs::DiffFileComponent.with_collection(diff_files, parallel_view: view == :parallel)
        .render_in(view_context)
    end

    def stream_diff_blobs(options, view_context)
      resource.diffs_for_streaming(options) do |diff_files_batch|
        response.stream.write(render_diff_files_collection(diff_files_batch, view_context))
      end
    end

    def sorted?
      false
    end

    class Request < SimpleDelegator
      def format
        Mime::Type.lookup("text/html")
      end
    end
  end
end
