# frozen_string_literal: true

class PersonalSnippet < Snippet
  self.allow_legacy_sti_class = true

  include WithUploads

  def parent_user
    author
  end

  def skip_project_check?
    true
  end
end
