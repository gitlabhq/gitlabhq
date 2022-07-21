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
          event_importer = case issue_event.event
                           when 'closed'
                             Gitlab::GithubImport::Importer::Events::Closed
                           when 'reopened'
                             Gitlab::GithubImport::Importer::Events::Reopened
                           when 'labeled', 'unlabeled'
                             Gitlab::GithubImport::Importer::Events::ChangedLabel
                           when 'renamed'
                             Gitlab::GithubImport::Importer::Events::Renamed
                           when 'milestoned', 'demilestoned'
                             Gitlab::GithubImport::Importer::Events::ChangedMilestone
                           when 'cross-referenced'
                             Gitlab::GithubImport::Importer::Events::CrossReferenced
                           when 'assigned', 'unassigned'
                             Gitlab::GithubImport::Importer::Events::ChangedAssignee
                           end

          if event_importer
            event_importer.new(project, user_finder).execute(issue_event)
          else
            Gitlab::GithubImport::Logger.debug(
              message: 'UNSUPPORTED_EVENT_TYPE',
              event_type: issue_event.event, event_github_id: issue_event.id
            )
          end
        end
      end
    end
  end
end
