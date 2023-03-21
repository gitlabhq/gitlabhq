# frozen_string_literal: true

module QA
  module Support
    module Matchers
      module HaveMatcher
        PREDICATE_TARGETS = %w[
          auto_devops_container
          element
          file_content
          assignee
          child_pipeline
          linked_pipeline
          content
          design
          file
          issue
          job
          package
          pipeline
          related_issue_item
          sast_status
          security_configuration_history_link
          snippet_description
          tag
          label
          variable
          system_note
          alert_with_title
          incident
          framework
        ].each do |predicate|
          RSpec::Matchers.define "have_#{predicate}" do |*args, **kwargs|
            match do |page_object|
              page_object.public_send("has_#{predicate}?", *args, **kwargs)
            end

            match_when_negated do |page_object|
              page_object.public_send("has_no_#{predicate}?", *args, **kwargs)
            end
          end
        end
      end
    end
  end
end
