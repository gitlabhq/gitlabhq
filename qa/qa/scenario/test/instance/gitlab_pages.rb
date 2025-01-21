# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class GitlabPages < All
          tags :gitlab_pages

          pipeline_mappings test_on_omnibus_nightly: %w[gitlab-pages]
        end
      end
    end
  end
end
