# Simplified version of Github API entities.
# It's mainly used to mimic Github API and integrate with Jira Development Panel.
#
module API
  module Github
    module Entities
      class Namespace < Grape::Entity
        expose :path, as: :login
      end

      class Repository < Grape::Entity
        expose :id
        expose :namespace, as: :owner, using: Namespace
        expose :path, as: :name
      end

      class BranchCommit < Grape::Entity
        expose :id, as: :sha
        expose :type do |_|
          'commit'
        end
      end

      class RepoCommit < Grape::Entity
        expose :id, as: :sha
        expose :author do |commit|
          {
            login: commit.author&.username,
            email: commit.author_email
          }
        end
        expose :committer do |commit|
          {
            login: commit.author&.username,
            email: commit.committer_email
          }
        end
        expose :commit do |commit|
          {
            author: {
              name: commit.author_name,
              email: commit.author_email,
              date: commit.authored_date.iso8601,
              type: 'User'
            },
            committer: {
              name: commit.committer_name,
              email: commit.committer_email,
              date: commit.committed_date.iso8601,
              type: 'User'
            },
            message: commit.safe_message
          }
        end
        expose :parents do |commit|
          commit.parent_ids.map { |id| { sha: id } }
        end
        expose :files do |commit|
          commit.diffs.diff_files.flat_map do |diff|
            additions = diff.added_lines
            deletions = diff.removed_lines

            if diff.new_file?
              {
                status: 'added',
                filename: diff.new_path,
                additions: additions,
                changes: additions
              }
            elsif diff.deleted_file?
              {
                status: 'removed',
                filename: diff.old_path,
                deletions: deletions,
                changes: deletions
              }
            elsif diff.renamed_file?
              [
                {
                  status: 'removed',
                  filename: diff.old_path,
                  deletions: deletions,
                  changes: deletions
                },
                {
                  status: 'added',
                  filename: diff.new_path,
                  additions: additions,
                  changes: additions
                }
              ]
            else
              {
                status: 'modified',
                filename: diff.new_path,
                additions: additions,
                deletions: deletions,
                changes: (additions + deletions)
              }
            end
          end
        end
      end

      class Branch < Grape::Entity
        expose :name

        expose :commit, using: BranchCommit do |repo_branch, options|
          options[:project].repository.commit(repo_branch.dereferenced_target)
        end
      end

      class User < Grape::Entity
        expose :id
        expose :username, as: :login
        expose :url do |user|
          Gitlab::Routing.url_helpers.user_url(user)
        end
      end

      class NoteableComment < Grape::Entity
        expose :id
        expose :author, as: :user, using: User
        expose :note, as: :body
        expose :created_at
      end

      class PullRequest < Grape::Entity
        expose :title
        expose :assignee, using: User
        expose :author, as: :user, using: User
        expose :created_at
        expose :description, as: :body
        # Since Jira service requests `/repos/-/jira/pulls` (without project
        # scope), we need to make it work with ID instead IID.
        expose :id, as: :number
        # GitHub doesn't have a "merged" or "closed" state. It's just "open" or
        # "closed".
        expose :state do |merge_request|
          case merge_request.state
          when 'opened', 'locked'
            'open'
          when 'merged'
            'closed'
          else
            merge_request.state
          end
        end
        expose :merged?, as: :merged
        expose :merged_at do |merge_request|
          merge_request.metrics&.merged_at
        end
        expose :closed_at do |merge_request|
          merge_request.metrics&.latest_closed_at
        end
        expose :updated_at
        expose :html_url do |merge_request|
          Gitlab::UrlBuilder.build(merge_request)
        end
        expose :head do
          expose :source_branch, as: :label
          expose :source_branch, as: :ref
          expose :source_project, as: :repo, using: Repository
        end
        expose :base do
          expose :target_branch, as: :label
          expose :target_branch, as: :ref
          expose :target_project, as: :repo, using: Repository
        end
      end
    end
  end
end
