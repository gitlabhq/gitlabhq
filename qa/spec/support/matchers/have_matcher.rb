# frozen_string_literal: true

module Matchers
  PREDICATE_TARGETS = %w[
    element
    file_content
    assignee
    child_pipeline
    content
    design
    file
    issue
    job
    package
    pipeline
    related_issue_item
    snippet_description
    tag
  ].each do |predicate|
    RSpec::Matchers.define "have_#{predicate}" do |*args, **kwargs|
      match do |page_object|
        page_object.public_send("has_#{predicate}?", *args, **kwargs) # rubocop:disable GitlabSecurity/PublicSend
      end

      match_when_negated do |page_object|
        page_object.public_send("has_no_#{predicate}?", *args, **kwargs) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
