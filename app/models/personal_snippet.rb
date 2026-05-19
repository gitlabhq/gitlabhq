# frozen_string_literal: true

class PersonalSnippet < Snippet
  self.allow_legacy_sti_class = true

  include WithUploads

  validates :organization_id, presence: true

  def self.reference_pattern
    # Avoid matching references that are definitely cross-project (non-personal)
    # snippet references using a lookbehind.  This still of course overlaps with
    # possible matches from Snippet.reference_pattern; SnippetReferenceFilter
    # therefore must run first, before PersonalSnippetReferenceFilter.
    @reference_pattern ||= %r{(?<![a-zA-Z0-9_./-])#{Regexp.escape(Snippet.reference_prefix)}(?<snippet>\d+)}
  end

  def self.link_reference_pattern
    @link_reference_pattern ||=
      compose_top_level_link_reference_pattern('snippets', /(?<snippet>\d+)/)
  end

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
