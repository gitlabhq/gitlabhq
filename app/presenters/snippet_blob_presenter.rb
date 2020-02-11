# frozen_string_literal: true

class SnippetBlobPresenter < BlobPresenter
  def highlighted_data
    return if blob.binary?

    highlight(plain: false)
  end

  def plain_highlighted_data
    return if blob.binary?

    highlight(plain: true)
  end

  def raw_path
    if snippet.is_a?(ProjectSnippet)
      raw_project_snippet_path(snippet.project, snippet)
    else
      raw_snippet_path(snippet)
    end
  end

  private

  def snippet
    blob.snippet
  end

  def language
    nil
  end
end
