module DiffForPath
  extend ActiveSupport::Concern

  def render_diff_for_path(diffs)
    diff_file = diffs.diff_files.find do |diff|
      diff.file_identifier == params[:file_identifier]
    end

    return render_404 unless diff_file

    if params[:viewer]
      viewer = params[:viewer] == 'rich' ? diff_file.rich_viewer : diff_file.simple_viewer
      return render_404 unless viewer

      render json: { html: view_to_html_string("projects/diffs/_viewer", viewer: viewer) }
    else
      render json: { html: view_to_html_string('projects/diffs/_content', diff_file: diff_file) }
    end
  end
end
