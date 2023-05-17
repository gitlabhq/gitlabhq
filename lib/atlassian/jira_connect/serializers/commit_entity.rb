# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class CommitEntity < BaseEntity
        CommitAuthor = Struct.new(:name, :email)

        expose :id
        expose :issueKeys do |commit|
          JiraIssueKeyExtractor.new(commit.safe_message).issue_keys
        end
        expose :id, as: :hash
        expose :short_id, as: :displayId
        expose :safe_message, as: :message
        expose :flags do |commit|
          if commit.merge_commit?
            ['MERGE_COMMIT']
          else
            []
          end
        end
        expose :author, using: JiraConnect::Serializers::AuthorEntity
        expose :fileCount do |commit|
          # n+1: https://gitlab.com/gitlab-org/gitaly/-/issues/3375
          Gitlab::GitalyClient.allow_n_plus_1_calls do
            commit.stats.total
          end
        end
        expose :files do |commit, options|
          # n+1: https://gitlab.com/gitlab-org/gitaly/-/issues/3374
          files = Gitlab::GitalyClient.allow_n_plus_1_calls do
            commit.diffs(max_files: 10).diff_files
          end
          JiraConnect::Serializers::FileEntity.represent files, options.merge(commit: commit)
        end
        expose :created_at, as: :authorTimestamp

        expose :url do |commit, options|
          project_commit_url(options[:project], commit.id)
        end

        private

        def author
          object.author || CommitAuthor.new(object.author_name, object.author_email)
        end
      end
    end
  end
end
