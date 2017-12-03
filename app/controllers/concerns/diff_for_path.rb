module DiffForPath
  extend ActiveSupport::Concern

  def render_diff_for_path(diffs)
    diff_file =
      if params[:file_identifier]
        find_diff_file_by_file_identifier(diffs)
      elsif params[:old_path] && params[:new_path]
        find_diff_file_by_paths(diffs)
      end

    return render_404 unless diff_file

    render json: { html: view_to_html_string('projects/diffs/_content', diff_file: diff_file) }
  end

  private

  def find_diff_file_by_file_identifier(diffs)
    diffs.diff_files.find do |diff|
      diff.file_identifier == params[:file_identifier]
    end
  end

  def find_diff_file_by_paths(diffs)
    diffs.diff_files.find do |diff|
      diff.old_path == params[:old_path] &&
      diff.new_path == params[:new_path]
    end
  end
end
