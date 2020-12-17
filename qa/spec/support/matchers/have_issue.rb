# frozen_string_literal: true

module Matchers
  module HaveIssue
    RSpec::Matchers.define :have_issue do |issue|
      match do |page_object|
        page_object.has_issue?(issue)
      end

      match_when_negated do |page_object|
        page_object.has_no_issue?(issue)
      end
    end
  end
end
