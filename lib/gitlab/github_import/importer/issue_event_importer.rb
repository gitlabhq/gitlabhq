# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssueEventImporter
        attr_reader :issue_event, :project, :client, :user_finder

        # issue_event - An instance of `Gitlab::GithubImport::Representation::IssueEvent`.
        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(issue_event, project, client)
          @issue_event = issue_event
          @project = project
          @client = client
          @user_finder = UserFinder.new(project, client)
        end

        def execute
          case issue_event.event
          when 'closed'
            Gitlab::GithubImport::Importer::Events::Closed.new(project, author_id)
              .execute(issue_event)
          when 'reopened'
            Gitlab::GithubImport::Importer::Events::Reopened.new(project, author_id)
              .execute(issue_event)
          when 'labeled', 'unlabeled'
            Gitlab::GithubImport::Importer::Events::ChangedLabel.new(project, author_id)
              .execute(issue_event)
          when 'renamed'
            Gitlab::GithubImport::Importer::Events::Renamed.new(project, author_id)
              .execute(issue_event)
          when 'milestoned', 'demilestoned'
            Gitlab::GithubImport::Importer::Events::ChangedMilestone.new(project, author_id)
              .execute(issue_event)
          when 'cross-referenced'
            Gitlab::GithubImport::Importer::Events::CrossReferenced.new(project, author_id)
              .execute(issue_event)
          else
            Gitlab::GithubImport::Logger.debug(
              message: 'UNSUPPORTED_EVENT_TYPE',
              event_type: issue_event.event, event_github_id: issue_event.id
            )
          end
        end

        private

        def author_id
          id, _status = user_finder.author_id_for(issue_event, author_key: :actor)
          id
        end
      end
    end
  end
end
