# frozen_string_literal: true

class PersonalSnippet < Snippet
  include WithUploads

  def web_url(only_path: nil)
    Gitlab::Routing.url_helpers.snippet_url(self, only_path: only_path)
  end
end
