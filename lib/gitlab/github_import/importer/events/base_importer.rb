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
            @user_finder = UserFinder.new(project, client)
          end

          # issue_event - An instance of `Gitlab::GithubImport::Representation::IssueEvent`.
          def execute(issue_event)
            raise NotImplementedError
          end

          private

          attr_reader :project, :user_finder

          def author_id(issue_event, author_key: :actor)
            user_finder.author_id_for(issue_event, author_key: author_key).first
          end

          def issuable_db_id(object)
            IssuableFinder.new(project, object).database_id
          end
        end
      end
    end
  end
end
