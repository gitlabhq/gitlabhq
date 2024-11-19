# frozen_string_literal: true

class IssueLink < ApplicationRecord
  include LinkableItem
  include EachBatch

  belongs_to :source, class_name: 'Issue'
  belongs_to :target, class_name: 'Issue'

  class << self
    def issuable_type
      :issue
    end
  end
end

IssueLink.prepend_mod_with('IssueLink')
