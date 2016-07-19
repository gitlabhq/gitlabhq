module DiffForPath
  extend ActiveSupport::Concern

  def render_diff_for_path(diffs, diff_refs, project)
    diff_file = safe_diff_files(diffs, diff_refs: diff_refs, repository: project.repository).find do |diff|
      diff.old_path == params[:old_path] && diff.new_path == params[:new_path]
    end

    return render_404 unless diff_file

    diff_commit = commit_for_diff(diff_file)
    blob = diff_file.blob(diff_commit)

    locals = {
      diff_file: diff_file,
      diff_commit: diff_commit,
      diff_refs: diff_refs,
      blob: blob,
      project: project
    }

    render json: { html: view_to_html_string('projects/diffs/_content', locals) }
  end
end
