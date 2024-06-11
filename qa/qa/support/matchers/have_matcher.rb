# frozen_string_literal: true

module QA
  module Support
    module Matchers
      module HaveMatcher
        PREDICATE_TARGETS = %w[
          alert_with_title
          artifacts_dropdown
          assignee
          auto_devops_container
          child_pipeline
          content
          delete_issue_button
          design
          element
          file
          file_content
          file_name
          framework
          incident
          issue
          job
          label
          linked_pipeline
          linked_resource
          package
          pipeline
          related_issue_item
          sast_status
          security_configuration_history_link
          skipped_job_in_group
          snippet_description
          stage
          system_note
          tag
          variable
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
