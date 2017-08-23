module RendersBlob
  extend ActiveSupport::Concern

  def blob_viewer_json(blob)
    blob.expand!

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

    viewer_json = BlobViewerSerializer.new(params: params).represent(viewer)

    viewer_json[:html] = view_to_html_string("projects/blob/_viewer", viewer: viewer, load_async: false)

    viewer_json
  end

  def render_blob_json(blob)
    json = blob_viewer_json(blob)
    return render_404 unless json

    render json: json
  end

  def conditionally_expand_blob(blob)
    blob.expand! if params[:expanded] == 'true'
  end
end
