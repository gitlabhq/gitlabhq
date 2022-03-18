# frozen_string_literal: true

class IssueLink < ApplicationRecord
  include FromUnion
  include IssuableLink

  belongs_to :source, class_name: 'Issue'
  belongs_to :target, class_name: 'Issue'

  scope :for_source_issue, ->(issue) { where(source_id: issue.id) }
  scope :for_target_issue, ->(issue) { where(target_id: issue.id) }

  class << self
    def issuable_type
      :issue
    end
  end
end

IssueLink.prepend_mod_with('IssueLink')
