# frozen_string_literal: true

class CommitUserMention < UserMention
  belongs_to :note
end
