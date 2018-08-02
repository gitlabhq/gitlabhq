# frozen_string_literal: true

class ProjectSnippet < Snippet
  # Elastic search configuration (it does not support STI)
  document_type 'snippet'
  index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')
  include Elastic::SnippetsSearch

  belongs_to :project
  belongs_to :author, class_name: "User"

  validates :project, presence: true

  # Scopes
  scope :fresh, -> { order("created_at DESC") }

  participant :author
  participant :notes_with_associations
end
