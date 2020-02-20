# frozen_string_literal: true

class SnippetBlobPresenter < BlobPresenter
  def rich_data
    return if blob.binary?

    if markup?
      blob.rendered_markup
    else
      highlight(plain: false)
    end
  end

  def plain_data
    return if blob.binary?

    highlight(plain: !markup?)
  end

  def raw_path
    if snippet.is_a?(ProjectSnippet)
      raw_project_snippet_path(snippet.project, snippet)
    else
      raw_snippet_path(snippet)
    end
  end

  private

  def markup?
    blob.rich_viewer&.partial_name == 'markup'
  end

  def snippet
    blob.snippet
  end

  def language
    nil
  end
end
