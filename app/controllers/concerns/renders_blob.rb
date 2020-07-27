# frozen_string_literal: true

module RendersBlob
  extend ActiveSupport::Concern

  def blob_json(blob)
    viewer =
      case params[:viewer]
      when 'rich'
        blob.rich_viewer
      when 'auxiliary'
        blob.auxiliary_viewer
      else
        blob.simple_viewer
      end

    return unless viewer

    {
      html: view_to_html_string("projects/blob/_viewer", viewer: viewer, load_async: false)
    }
  end

  def render_blob_json(blob)
    json = blob_json(blob)
    return render_404 unless json

    render json: json
  end

  def conditionally_expand_blob(blob)
    conditionally_expand_blobs([blob])
  end

  def conditionally_expand_blobs(blobs)
    return unless params[:expanded] == 'true'

    blobs.each { |blob| blob.expand! }
  end
end
