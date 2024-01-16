# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        # Base class for importing issue events during project import from GitHub
        class BaseImporter
          # project - An instance of `Project`.
          # client - An instance of `Gitlab::GithubImport::Client`.
          def initialize(project, client)
            @project = project
            @client = client
            @user_finder = UserFinder.new(project, client)
          end

          # issue_event - An instance of `Gitlab::GithubImport::Representation::IssueEvent`.
          def execute(issue_event)
            raise NotImplementedError
          end

          private

          attr_reader :project, :user_finder, :client

          def author_id(issue_event, author_key: :actor)
            user_finder.author_id_for(issue_event, author_key: author_key).first
          end

          def issuable_db_id(object)
            IssuableFinder.new(project, object).database_id
          end

          def issuable_type(issue_event)
            merge_request_event?(issue_event) ? MergeRequest.name : Issue.name
          end

          def merge_request_event?(issue_event)
            issue_event.issuable_type == MergeRequest.name
          end

          def resource_event_belongs_to(issue_event)
            belongs_to_key = merge_request_event?(issue_event) ? :merge_request_id : :issue_id
            { belongs_to_key => issuable_db_id(issue_event) }
          end

          def import_settings
            @import_settings ||= Gitlab::GithubImport::Settings.new(project)
          end
        end
      end
    end
  end
end
