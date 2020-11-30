# frozen_string_literal: true

class SnippetBlob
  include BlobLike

  attr_reader :snippet

  def initialize(snippet)
    @snippet = snippet
  end

  delegate :id, to: :snippet

  def name
    snippet.file_name
  end

  alias_method :path, :name

  def size
    data.bytesize
  end

  def commit_id
    nil
  end

  def data
    snippet.content
  end

  def rendered_markup
    return unless Gitlab::MarkupHelper.gitlab_markdown?(name)

    Banzai.render_field(snippet, :content)
  end
end
