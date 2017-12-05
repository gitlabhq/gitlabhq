module Gitlab
  module GitalyClient
    class ConflictsService
      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def list_conflict_files(our_commit_oid, their_commit_oid)
        request = Gitaly::ListConflictFilesRequest.new(
          repository: @gitaly_repo,
          our_commit_oid: our_commit_oid,
          their_commit_oid: their_commit_oid
        )
        response = GitalyClient.call(@repository.storage, :conflicts_service, :list_conflict_files, request)
        files = []
        header = nil
        content = nil

        response.each do |msg|
          msg.files.each do |gitaly_file|
            if gitaly_file.header
              # Add previous file to the collection, except on first iteration
              files << conflict_file_from_gitaly(header, content) if header

              header = gitaly_file.header
              content = ""
            else
              # Append content to curret file
              content << gitaly_file.content
            end
          end
        end

        # Add leftover file, if any
        files << conflict_file_from_gitaly(header, content) if header

        files
      end

      private

      def conflict_file_from_gitaly(header, content)
        Gitlab::Git::Conflict::File.new(
          Gitlab::GitalyClient::Util.git_repository(header.repository),
          header.commit_oid,
          conflict_from_gitaly_file_header(header),
          content
        )
      end

      def conflict_from_gitaly_file_header(header)
        {
          ours: { path: header.our_path, mode: header.our_mode },
          theirs: { path: header.their_path }
        }
      end
    end
  end
end
