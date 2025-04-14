# frozen_string_literal: true

module RapidDiffsResource
  extend ActiveSupport::Concern

  def diffs_stream_url(resource, offset = nil, diff_view = nil)
    return if offset && offset > resource.diffs_for_streaming.diff_files.count

    diffs_stream_resource_url(resource, offset, diff_view)
  end

  def diff_files_metadata
    return render_404 unless rapid_diffs_enabled?
    return render_404 unless diffs_resource.present?

    render json: {
      diff_files: DiffFileMetadataEntity.represent(diffs_resource.raw_diff_files(sorted: true))
    }
  end

  def diffs_stats
    return render_404 unless rapid_diffs_enabled?
    return render_404 unless diffs_resource.present?

    render json: RapidDiffs::DiffsStatsEntity.represent(
      diffs_resource,
      {
        email_path: email_format_path,
        diff_path: complete_diff_path
      }
    )
  end

  private

  def rapid_diffs_enabled?
    ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)
  end

  def diffs_resource
    raise NotImplementedError
  end

  def diffs_stream_resource_url(resource, offset, diff_view)
    raise NotImplementedError
  end

  # When overridden this mthod should return a path to view diffs in an email-friendly format.
  def email_format_path
    nil
  end

  # When overridden this method should return a path to view the complete diffs in the UI.
  def complete_diff_path
    nil
  end
end
