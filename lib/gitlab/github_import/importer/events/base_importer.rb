# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        # Base class for importing issue events during project import from GitHub
        class BaseImporter
          # project - An instance of `Project`.
          # user_finder - An instance of `Gitlab::GithubImport::UserFinder`.
          def initialize(project, user_finder)
            @project = project
            @user_finder = user_finder
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
        end
      end
    end
  end
end
