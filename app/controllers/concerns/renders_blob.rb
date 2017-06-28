module RendersBlob
  extend ActiveSupport::Concern

  def render_blob_json(blob)
    viewer =
      case params[:viewer]
      when 'rich'
        blob.rich_viewer
      when 'auxiliary'
        blob.auxiliary_viewer
      else
        blob.simple_viewer
      end
    return render_404 unless viewer

    render json: {
      html: view_to_html_string("projects/blob/_viewer", viewer: viewer, load_async: false)
    }
  end

  def conditionally_expand_blob(blob)
    blob.expand! if params[:expanded] == 'true'
  end
end
