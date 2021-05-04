# frozen_string_literal: true

module Gitlab
  module Changelog
    # A class used for committing a release's changelog to a Git repository.
    class Committer
      def initialize(project, user)
        @project = project
        @user = user
      end

      # Commits a release's changelog to a file on a branch.
      #
      # The `release` argument is a `Gitlab::Changelog::Release` for which to
      # update the changelog.
      #
      # The `file` argument specifies the path to commit the changes to.
      #
      # The `branch` argument specifies the branch to commit the changes on.
      #
      # The `message` argument specifies the commit message to use.
      def commit(release:, file:, branch:, message:)
        # When retrying, we need to reprocess the existing changelog from
        # scratch, otherwise we may end up throwing away changes. As such, all
        # the logic is contained within the retry block.
        Retriable.retriable(on: Error) do
          commit = Gitlab::Git::Commit.last_for_path(
            @project.repository,
            branch,
            file,
            literal_pathspec: true
          )

          content = blob_content(file, commit)

          # If the release has already been added (e.g. concurrently by another
          # API call), we don't want to add it again.
          break if content&.match?(release.header_start_pattern)

          service = Files::MultiService.new(
            @project,
            @user,
            commit_message: message,
            branch_name: branch,
            start_branch: branch,
            actions: [
              {
                action: content ? 'update' : 'create',
                content: Generator.new(content.to_s).add(release),
                file_path: file,
                last_commit_id: commit&.sha
              }
            ]
          )

          result = service.execute

          raise Error, result[:message] if result[:status] != :success
        end
      end

      def blob_content(file, commit = nil)
        return unless commit

        @project.repository.blob_at(commit.sha, file)&.data
      end
    end
  end
end
