# frozen_string_literal: true

class SnippetBlobPresenter < BlobPresenter
  def highlighted_data
    return if blob.binary?

    if blob.rich_viewer&.partial_name == 'markup'
      blob.rendered_markup
    else
      highlight
    end
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
