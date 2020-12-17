# frozen_string_literal: true

module Matchers
  module HaveAssignee
    RSpec::Matchers.define :have_assignee do |assignee|
      match do |page_object|
        page_object.has_assignee?(assignee)
      end

      match_when_negated do |page_object|
        page_object.has_no_assignee?(assignee)
      end
    end
  end
end
