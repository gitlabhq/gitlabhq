# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class BranchEntity < BaseEntity
        expose :id do |branch|
          Digest::SHA256.hexdigest(branch.name)
        end
        expose :issueKeys do |branch, options|
          JiraIssueKeyExtractors::Branch.new(options[:project], branch.name).issue_keys
        end
        expose :name
        expose :lastCommit, using: JiraConnect::Serializers::CommitEntity do |branch, options|
          options[:project].commit(branch.dereferenced_target)
        end
        expose :url do |branch, options|
          project_commits_url(options[:project], branch.name)
        end
        expose :createPullRequestUrl do |branch, options|
          project_new_merge_request_url(
            options[:project],
            merge_request: {
              source_branch: branch.name
            }
          )
        end
      end
    end
  end
end
