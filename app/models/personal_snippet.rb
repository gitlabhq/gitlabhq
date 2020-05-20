# frozen_string_literal: true

class PersonalSnippet < Snippet
  include WithUploads

  def skip_project_check?
    true
  end
end
