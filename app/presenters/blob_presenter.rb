# frozen_string_literal: true

class BlobPresenter < Gitlab::View::Presenter::Simple
  presents :blob

  def highlight(plain: nil)
    plain = blob.no_highlighting? if plain.nil?

    Gitlab::Highlight.highlight(
      blob.path,
      blob.data,
      language: blob.language_from_gitattributes,
      plain: plain
    )
  end
end
