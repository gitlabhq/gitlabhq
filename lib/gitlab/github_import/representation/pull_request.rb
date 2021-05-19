# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class PullRequest
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :iid, :title, :description, :source_branch,
                         :source_branch_sha, :target_branch, :target_branch_sha,
                         :milestone_number, :author, :assignee, :created_at,
                         :updated_at, :merged_at, :source_repository_id,
                         :target_repository_id, :source_repository_owner, :merged_by

        # Builds a PR from a GitHub API response.
        #
        # issue - An instance of `Sawyer::Resource` containing the PR details.
        def self.from_api_response(pr)
          assignee = Representation::User.from_api_response(pr.assignee) if pr.assignee
          user = Representation::User.from_api_response(pr.user) if pr.user
          merged_by = Representation::User.from_api_response(pr.merged_by) if pr.merged_by

          hash = {
            iid: pr.number,
            github_id: pr.number,
            title: pr.title,
            description: pr.body,
            source_branch: pr.head.ref,
            target_branch: pr.base.ref,
            source_branch_sha: pr.head.sha,
            target_branch_sha: pr.base.sha,
            source_repository_id: pr.head&.repo&.id,
            target_repository_id: pr.base&.repo&.id,
            source_repository_owner: pr.head&.user&.login,
            state: pr.state == 'open' ? :opened : :closed,
            milestone_number: pr.milestone&.number,
            author: user,
            assignee: assignee,
            created_at: pr.created_at,
            updated_at: pr.updated_at,
            merged_at: pr.merged_at,
            merged_by: merged_by
          }

          new(hash)
        end

        # Builds a new PR using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          hash = Representation.symbolize_hash(raw_hash)

          hash[:state] = hash[:state].to_sym
          hash[:author] &&= Representation::User.from_json_hash(hash[:author])

          # Assignees are optional so we only convert it from a Hash if one was
          # set.
          hash[:assignee] &&= Representation::User.from_json_hash(hash[:assignee])
          hash[:merged_by] &&= Representation::User.from_json_hash(hash[:merged_by])

          new(hash)
        end

        # attributes - A Hash containing the raw PR details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def truncated_title
          title.truncate(255)
        end

        # Returns a formatted source branch.
        #
        # For cross-project pull requests the branch name will be in the format
        # `github/fork/owner-name/branch-name`.
        def formatted_source_branch
          if cross_project? && source_repository_owner
            "github/fork/#{source_repository_owner}/#{source_branch}"
          elsif source_branch == target_branch
            # Sometimes the source and target branch are the same, but GitLab
            # doesn't support this. This can happen when both the user and
            # source repository have been deleted, and the PR was submitted from
            # the fork's master branch.
            "#{source_branch}-#{iid}"
          else
            source_branch
          end
        end

        def state
          if merged_at
            :merged
          else
            attributes[:state]
          end
        end

        def cross_project?
          return true unless source_repository_id

          source_repository_id != target_repository_id
        end

        def issuable_type
          'MergeRequest'
        end
      end
    end
  end
end
