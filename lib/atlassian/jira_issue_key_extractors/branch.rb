# frozen_string_literal: true

module Atlassian
  module JiraIssueKeyExtractors
    class Branch
      def self.has_keys?(project, branch_name)
        new(project, branch_name).issue_keys.any?
      end

      def initialize(project, branch_name)
        @project = project
        @branch_name = branch_name
      end

      # Extract Jira issue keys from the branch name and associated open merge request.
      # Use BatchLoader to load this data without N+1 queries when serializing multiple branches
      # in `Atlassian::JiraConnect::Serializers::BranchEntity`.
      def issue_keys
        BatchLoader.for(branch_name).batch do |branch_names, loader|
          merge_requests = MergeRequest
            .select(:description, :source_branch, :title)
            .from_project(project)
            .from_source_branches(branch_names)
            .opened

          branch_names.each do |branch_name|
            related_merge_request = merge_requests.find { |mr| mr.source_branch == branch_name }

            key_sources = [branch_name, related_merge_request&.title, related_merge_request&.description].compact
            issue_keys = JiraIssueKeyExtractor.new(key_sources).issue_keys

            loader.call(branch_name, issue_keys)
          end
        end
      end

      private

      attr_reader :branch_name, :project
    end
  end
end
