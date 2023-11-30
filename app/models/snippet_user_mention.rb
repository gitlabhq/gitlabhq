# frozen_string_literal: true

class SnippetUserMention < UserMention
  belongs_to :snippet
  belongs_to :note
end
