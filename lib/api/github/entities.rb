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
    end
  end
end
