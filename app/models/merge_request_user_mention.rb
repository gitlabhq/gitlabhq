# frozen_string_literal: true

class MergeRequestUserMention < UserMention
  belongs_to :merge_request
  belongs_to :note
end
