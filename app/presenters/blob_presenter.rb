# frozen_string_literal: true

class BlobPresenter < Gitlab::View::Presenter::Delegated
  presents :blob

  def highlight(plain: nil)
    load_all_blob_data

    Gitlab::Highlight.highlight(
      blob.path,
      blob.data,
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
end
