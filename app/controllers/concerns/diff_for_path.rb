module DiffForPath
  extend ActiveSupport::Concern

  def render_diff_for_path(diffs)
    diff_file = diffs.diff_files.find do |diff|
      diff.file_identifier == params[:file_identifier]
    end

    return render_404 unless diff_file

    diff_commit = commit_for_diff(diff_file)
    blob = diff_file.blob(diff_commit)

    locals = {
      diff_file: diff_file,
      diff_commit: diff_commit,
      diff_refs: diffs.diff_refs,
      blob: blob,
      project: project
    }

    render json: { html: view_to_html_string('projects/diffs/_content', locals) }
  end
end
