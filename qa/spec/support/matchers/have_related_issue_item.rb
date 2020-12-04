# frozen_string_literal: true

module Matchers
  module HaveRelatedIssueItem
    RSpec::Matchers.define :have_related_issue_item do
      match do |page_object|
        page_object.has_related_issue_item?
      end

      match_when_negated do |page_object|
        page_object.has_no_related_issue_item?
      end
    end
  end
end
