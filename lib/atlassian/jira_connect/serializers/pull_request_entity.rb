# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class PullRequestEntity < BaseEntity
        STATUS_MAPPING = {
          'opened' => 'OPEN',
          'locked' => 'OPEN',
          'merged' => 'MERGED',
          'closed' => 'DECLINED'
        }.freeze

        expose :id, format_with: :string
        expose :issueKeys do |mr|
          JiraIssueKeyExtractor.new(mr.title, mr.description).issue_keys
        end
        expose :displayId do |mr|
          mr.to_reference(full: true)
        end
        expose :title
        expose :author, using: JiraConnect::Serializers::AuthorEntity
        expose :reviewers do |mr|
          JiraConnect::Serializers::ReviewerEntity.represent(mr.merge_request_reviewers, merge_request: mr)
        end
        expose :commentCount do |mr|
          if options[:user_notes_count]
            options[:user_notes_count].fetch(mr.id, 0)
          else
            mr.user_notes_count
          end
        end
        expose :source_branch, as: :sourceBranch
        expose :target_branch, as: :destinationBranch
        expose :lastUpdate do |mr|
          mr.last_edited_at || mr.created_at
        end
        expose :status do |mr|
          STATUS_MAPPING[mr.state] || 'UNKNOWN'
        end

        expose :sourceBranchUrl do |mr|
          project_commits_url(mr.project, mr.source_branch)
        end
        expose :url do |mr|
          merge_request_url(mr)
        end
      end
    end
  end
end
