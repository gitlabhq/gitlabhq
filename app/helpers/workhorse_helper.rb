# frozen_string_literal: true

# Helpers to send Git blobs, diffs, patches or archives through Workhorse.
# Workhorse will also serve files when using `send_file`.
#
# Every emit point below calls `verify_workhorse_api!` first. This is the
# canonical chokepoint for the Gitlab-Workhorse-Send-Data response header,
# so a request that did not transit Workhorse cannot extract Gitaly
# credentials or pre-signed object storage URLs from these helpers.
module WorkhorseHelper
  # Send a Git blob through Workhorse
  def send_git_blob(repository, blob, inline: true)
    verify_workhorse_api!
    headers.store(*Gitlab::Workhorse.send_git_blob(repository, blob))

    headers['Content-Disposition'] = content_disposition_for_blob(blob, inline)

    # If enabled, this will override the values set above
    workhorse_set_content_type!

    render plain: ""
  end

  # Send a Git diff through Workhorse
  def send_git_diff(repository, diff_refs)
    verify_workhorse_api!
    headers.store(*Gitlab::Workhorse.send_git_diff(repository, diff_refs))
    headers['Content-Disposition'] = 'inline'
    head :ok
  end

  # Send a Git patch through Workhorse
  def send_git_patch(repository, diff_refs)
    verify_workhorse_api!
    headers.store(*Gitlab::Workhorse.send_git_patch(repository, diff_refs))
    headers['Content-Disposition'] = 'inline'
    head :ok
  end

  # Archive a Git repository and send it through Workhorse
  def send_git_archive(repository, **kwargs)
    verify_workhorse_api!
    headers.store(*Gitlab::Workhorse.send_git_archive(repository, **kwargs))
    head :ok
  end

  # Send an entry from artifacts through Workhorse and set safe content type
  def send_artifacts_entry(file, entry)
    verify_workhorse_api!
    headers.store(*Gitlab::Workhorse.send_artifacts_entry(file, entry))
    headers.store(*Gitlab::Workhorse.detect_content_type)

    head :ok
  end

  def send_dependency(dependency_headers, url, filename, ssrf_params: {})
    verify_workhorse_api!
    headers.store(*Gitlab::Workhorse.send_dependency(dependency_headers, url, **ssrf_params))
    headers['Content-Disposition'] =
      ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: filename)
    headers['Content-Type'] = 'application/gzip'

    head :ok
  end

  def set_workhorse_internal_api_content_type
    headers['Content-Type'] = Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
  end

  def workhorse_set_content_type!
    headers[Gitlab::Workhorse::DETECT_HEADER] = "true"
  end

  def content_disposition_for_blob(blob, inline)
    return inline_content_disposition(blob) if inline

    attachment_content_disposition(blob)
  end

  def inline_content_disposition(blob)
    # We need to validate the .xhtml extension to avoid content sniffing
    # since some specific browsers ignore the Content-Disposition header.
    #
    # Using `split` instead of `File.extname` to handle files with multiple extensions
    #
    # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/458229
    filename = blob.name.ends_with?('.xhtml') ? blob.name.split('.')[0] : nil

    ActionDispatch::Http::ContentDisposition.format(disposition: 'inline', filename: filename)
  end

  def attachment_content_disposition(blob)
    ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: blob.name)
  end
end
