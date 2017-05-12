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
      html: view_to_html_string("projects/blob/_viewer", viewer: viewer, load_asynchronously: false)
    }
  end

  def override_max_blob_size(blob)
    blob.override_max_size! if params[:override_max_size] == 'true'
  end
end
