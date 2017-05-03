module RendersBlob
  extend ActiveSupport::Concern

  def render_blob_json(blob)
    viewer =
      if params[:viewer] == 'rich'
        blob.rich_viewer
      else
        blob.simple_viewer
      end
    return render_404 unless viewer

    render json: {
      html: view_to_html_string("projects/blob/_viewer", viewer: viewer, load_asynchronously: false)
    }
  end
end
