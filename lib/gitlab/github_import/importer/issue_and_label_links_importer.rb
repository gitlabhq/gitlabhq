# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssueAndLabelLinksImporter
        attr_reader :issue, :project, :client

        # issue - An instance of `Gitlab::GithubImport::Representation::Issue`.
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(issue, project, client)
          @issue = issue
          @project = project
          @client = client
        end

        def execute
          IssueImporter.import_if_issue(issue, project, client)
          LabelLinksImporter.new(issue, project, client).execute
        end
      end
    end
  end
end
