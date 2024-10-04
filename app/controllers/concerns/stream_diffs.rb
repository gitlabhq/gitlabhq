# frozen_string_literal: true

module StreamDiffs
  extend ActiveSupport::Concern
  include ActionController::Live

  def diffs
    return render_404 unless rapid_diffs_enabled?

    stream_headers

    offset = { offset_index: params.permit(:offset)[:offset].to_i }

    stream_diff_files(options.merge(offset))
  rescue StandardError => e
    Gitlab::AppLogger.error("Error streaming diffs: #{e.message}")
    response.stream.write e.message
  ensure
    response.stream.close
  end

  private

  def rapid_diffs_enabled?
    ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)
  end

  def resource
    raise NotImplementedError
  end

  def options
    {}
  end

  def view
    helpers.diff_view
  end

  def stream_diff_files(options)
    resource.diffs_for_streaming(options).diff_files.each do |diff_file|
      response.stream.write(render_diff_file(diff_file))
    end
  end

  def render_diff_file(diff_file)
    render_to_string(
      ::RapidDiffs::DiffFileComponent.new(diff_file: diff_file, parallel_view: view == :parallel),
      layout: false
    )
  end
end
