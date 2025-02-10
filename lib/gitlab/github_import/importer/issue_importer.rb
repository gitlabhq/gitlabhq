# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssueImporter
        include Gitlab::Import::UsernameMentionRewriter
        include Gitlab::GithubImport::PushPlaceholderReferences

        attr_reader :project, :issue, :client, :user_finder, :milestone_finder,
          :issuable_finder, :mapper

        # Imports an issue if it's a regular issue and not a pull request.
        def self.import_if_issue(issue, project, client)
          new(issue, project, client).execute unless issue.pull_request?
        end

        # issue - An instance of `Gitlab::GithubImport::Representation::Issue`.
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(issue, project, client)
          @issue = issue
          @project = project
          @client = client
          @user_finder = GithubImport::UserFinder.new(project, client)
          @milestone_finder = MilestoneFinder.new(project)
          @issuable_finder = GithubImport::IssuableFinder.new(project, issue)
          @mapper = Gitlab::GithubImport::ContributionsMapper.new(project)
        end

        def execute
          new_issue = create_issue
          issuable_finder.cache_database_id(new_issue.id)

          push_issue_placeholder_references(new_issue)

          new_issue
        end

        private

        # Returns a Hash of { GitLabUserId => GitHubUserId }
        # that can be used for both importing and pushing user references.
        def issue_assignee_map
          @map ||= issue.assignees.each_with_object({}) do |assignee, map|
            gitlab_user_id = user_finder.user_id_for(assignee, ghost: false)
            next unless gitlab_user_id

            map[gitlab_user_id] = assignee[:id]
          end
        end

        # Creates a new GitLab issue for the current GitHub issue.
        def create_issue
          author_id, author_found = user_finder.author_id_for(issue)

          description = wrap_mentions_in_backticks(issue.description)
          description = MarkdownText.format(description, issue.author, author_found)

          assignee_ids = issue_assignee_map.keys

          attributes = {
            iid: issue.iid,
            title: issue.truncated_title,
            author_id: author_id,
            assignee_ids: assignee_ids,
            project_id: project.id,
            namespace_id: project.project_namespace_id,
            description: description,
            milestone_id: milestone_finder.id_for(issue),
            state_id: ::Issue.available_states[issue.state],
            created_at: issue.created_at,
            updated_at: issue.updated_at,
            work_item_type_id: issue.work_item_type_id,
            imported_from: ::Import::SOURCE_GITHUB
          }

          project.issues.create!(attributes.merge(importing: true))
        end

        def push_issue_placeholder_references(new_issue)
          return unless mapper.user_mapping_enabled?

          user_mapper = mapper.user_mapper

          push_with_record(new_issue, :author_id, issue.author&.id, user_mapper)

          new_issue.issue_assignees.each do |issue_assignee|
            github_user_id = issue_assignee_map[issue_assignee.user_id]

            push_with_composite_key(
              issue_assignee,
              :user_id,
              { 'user_id' => issue_assignee.user_id, 'issue_id' => issue_assignee.issue_id },
              github_user_id,
              user_mapper
            )
          end
        end
      end
    end
  end
end
