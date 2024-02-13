# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssueImporter
        attr_reader :project, :issue, :client, :user_finder, :milestone_finder,
                    :issuable_finder

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
        end

        def execute
          new_issue = create_issue
          issuable_finder.cache_database_id(new_issue.id)
          new_issue
        end

        private

        # Creates a new GitLab issue for the current GitHub issue.
        def create_issue
          author_id, author_found = user_finder.author_id_for(issue)

          description = MarkdownText.format(issue.description, issue.author, author_found)

          assignee_ids = issue.assignees.filter_map do |assignee|
            user_finder.user_id_for(assignee)
          end

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
            work_item_type_id: issue.work_item_type_id
          }

          project.issues.create!(attributes.merge(importing: true))
        end
      end
    end
  end
end
