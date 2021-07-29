# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssueImporter
        include Gitlab::Import::DatabaseHelpers

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
          Issue.transaction do
            if (issue_id = create_issue)
              create_assignees(issue_id)
              issuable_finder.cache_database_id(issue_id)
            end
          end
        end

        # Creates a new GitLab issue for the current GitHub issue.
        #
        # Returns the ID of the created issue as an Integer. If the issue
        # couldn't be created this method will return `nil` instead.
        def create_issue
          author_id, author_found = user_finder.author_id_for(issue)

          description =
            MarkdownText.format(issue.description, issue.author, author_found)

          attributes = {
            iid: issue.iid,
            title: issue.truncated_title,
            author_id: author_id,
            project_id: project.id,
            description: description,
            milestone_id: milestone_finder.id_for(issue),
            state_id: ::Issue.available_states[issue.state],
            created_at: issue.created_at,
            updated_at: issue.updated_at
          }

          insert_and_return_id(attributes, project.issues)
        rescue ActiveRecord::InvalidForeignKey
          # It's possible the project has been deleted since scheduling this
          # job. In this case we'll just skip creating the issue.
        end

        # Stores all issue assignees in the database.
        #
        # issue_id - The ID of the created issue.
        def create_assignees(issue_id)
          assignees = []

          issue.assignees.each do |assignee|
            if (user_id = user_finder.user_id_for(assignee))
              assignees << { issue_id: issue_id, user_id: user_id }
            end
          end

          Gitlab::Database.main.bulk_insert(IssueAssignee.table_name, assignees) # rubocop:disable Gitlab/BulkInsert
        end
      end
    end
  end
end
