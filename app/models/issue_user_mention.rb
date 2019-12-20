# frozen_string_literal: true

class IssueUserMention < UserMention
  belongs_to :issue
  belongs_to :note
end
