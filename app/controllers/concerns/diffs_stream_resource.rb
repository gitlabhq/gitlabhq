# frozen_string_literal: true

module DiffsStreamResource
  extend ActiveSupport::Concern

  def diffs_stream_url(resource, offset = nil, diff_view = nil)
    return if offset && offset > resource.diffs_for_streaming.diff_files.count

    diffs_stream_resource_url(resource, offset, diff_view)
  end

  private

  def diffs_stream_resource_url(resource, offset, diff_view)
    raise NotImplementedError
  end
end
