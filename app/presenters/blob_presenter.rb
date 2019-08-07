# frozen_string_literal: true

class BlobPresenter < Gitlab::View::Presenter::Delegated
  presents :blob

  def highlight(since: nil, to: nil, plain: nil)
    load_all_blob_data

    Gitlab::Highlight.highlight(
      blob.path,
      limited_blob_data(since: since, to: to),
      since: since,
      language: blob.language_from_gitattributes,
      plain: plain
    )
  end

  def web_url
    Gitlab::Routing.url_helpers.project_blob_url(blob.repository.project, File.join(blob.commit_id, blob.path))
  end

  private

  def load_all_blob_data
    blob.load_all_data! if blob.respond_to?(:load_all_data!)
  end

  def limited_blob_data(since: nil, to: nil)
    return blob.data if since.blank? || to.blank?

    limited_blob_lines(since, to).join
  end

  def limited_blob_lines(since, to)
    all_lines[since - 1..to - 1]
  end

  def all_lines
    @all_lines ||= blob.data.lines
  end
end
