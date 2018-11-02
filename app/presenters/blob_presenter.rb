# frozen_string_literal: true

class BlobPresenter < Gitlab::View::Presenter::Simple
  presents :blob

  def highlight(plain: nil)
    blob.load_all_data! if blob.respond_to?(:load_all_data!)

    Gitlab::Highlight.highlight(
      blob.path,
      blob.data,
      language: blob.language_from_gitattributes,
      plain: plain
    )
  end
end
