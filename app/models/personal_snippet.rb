# frozen_string_literal: true

class PersonalSnippet < Snippet
  self.allow_legacy_sti_class = true

  include WithUploads

  validates :organization_id, presence: true

  def parent_user
    author
  end

  def skip_project_check?
    true
  end

  def uploads_sharding_key
    { organization_id: organization_id }
  end
end
