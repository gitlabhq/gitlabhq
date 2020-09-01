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
          commit.stats.total
        end
        expose :files do |commit, options|
          files = commit.diffs(max_files: 10).diff_files
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
