# Helpers to send Git blobs, diffs, patches or archives through Workhorse.
# Workhorse will also serve files when using `send_file`.
module WorkhorseHelper
  # Send a Git blob through Workhorse
  def send_git_blob(repository, blob)
    headers.store(*Gitlab::Workhorse.send_git_blob(repository, blob))
    headers['Content-Disposition'] = 'inline'
    headers['Content-Type'] = safe_content_type(blob)
    head :ok # 'render nothing: true' messes up the Content-Type
  end

  # Send a Git diff through Workhorse
  def send_git_diff(repository, diff_refs)
    headers.store(*Gitlab::Workhorse.send_git_diff(repository, diff_refs))
    headers['Content-Disposition'] = 'inline'
    head :ok
  end

  # Send a Git patch through Workhorse
  def send_git_patch(repository, diff_refs)
    headers.store(*Gitlab::Workhorse.send_git_patch(repository, diff_refs))
    headers['Content-Disposition'] = 'inline'
    head :ok
  end

  # Archive a Git repository and send it through Workhorse
  def send_git_archive(repository, ref:, format:)
    headers.store(*Gitlab::Workhorse.send_git_archive(repository, ref: ref, format: format))
    head :ok
  end

  # Send an entry from artifacts through Workhorse
  def send_artifacts_entry(build, entry)
    headers.store(*Gitlab::Workhorse.send_artifacts_entry(build, entry))
    head :ok
  end
end
