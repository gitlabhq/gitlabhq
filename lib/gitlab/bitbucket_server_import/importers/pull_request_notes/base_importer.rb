# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      module PullRequestNotes
        # Base class for importing pull request notes during project import from Bitbucket Server
        class BaseImporter
          include Loggable
          include ::Gitlab::Import::UsernameMentionRewriter
          include ::Import::PlaceholderReferences::Pusher

          # @param project [Project]
          # @param merge_request [MergeRequest]
          def initialize(project, merge_request)
            @project = project
            @user_finder = UserFinder.new(project)
            @formatter = Gitlab::ImportFormatter.new
            @merge_request = merge_request
          end

          def execute(_args)
            raise NotImplementedError
          end

          private

          attr_reader :project, :user_finder, :merge_request
        end
      end
    end
  end
end
