# frozen_string_literal: true

module StreamDiffs
  extend ActiveSupport::Concern
  include ActionController::Live
  include DiffHelper

  def diffs
    return render_404 unless rapid_diffs_enabled?

    stream_headers

    offset = { offset_index: params.permit(:offset)[:offset].to_i }

    stream_diff_files(streaming_diff_options.merge(offset))
  rescue StandardError => e
    Gitlab::AppLogger.error("Error streaming diffs: #{e.message}")
    response.stream.write e.message
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

  def stream_diff_files(options)
    return unless resource

    # NOTE: This is a temporary flag to test out the new diff_blobs
    if !!ActiveModel::Type::Boolean.new.cast(params.permit(:diff_blobs)[:diff_blobs])
      stream_diff_blobs(options)
    else
      resource.diffs_for_streaming(options).diff_files.each do |diff_file|
        response.stream.write(render_diff_file(diff_file))
      end
    end
  end

  def render_diff_file(diff_file)
    render_to_string(
      ::RapidDiffs::DiffFileComponent.new(diff_file: diff_file, parallel_view: view == :parallel),
      layout: false
    )
  end

  def stream_diff_blobs(options)
    resource.diffs_for_streaming(options) do |diff_files_batch|
      diff_files_batch.each do |diff_file|
        response.stream.write(render_diff_file(diff_file))
      end
    end
  end

  class Request < SimpleDelegator
    def format
      Mime::Type.lookup("text/html")
    end
  end
end
