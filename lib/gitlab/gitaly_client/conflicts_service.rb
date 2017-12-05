module Gitlab
  module GitalyClient
    class ConflictsService
      MAX_MSG_SIZE = 128.kilobytes.freeze

      def initialize(repository, our_commit_oid, their_commit_oid)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
        @our_commit_oid = our_commit_oid
        @their_commit_oid = their_commit_oid
      end

      def list_conflict_files
        request = Gitaly::ListConflictFilesRequest.new(
          repository: @gitaly_repo,
          our_commit_oid: @our_commit_oid,
          their_commit_oid: @their_commit_oid
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

      def resolve_conflicts(target_repository, user, files, source_branch, target_branch, commit_message)
        reader = GitalyClient.binary_stringio(files.to_json)

        req_enum = Enumerator.new do |y|
          header = resolve_conflicts_request_header(target_repository, user, source_branch, target_branch, commit_message)
          y.yield Gitaly::ResolveConflictsRequest.new(header: header)

          until reader.eof?
            chunk = reader.read(MAX_MSG_SIZE)

            y.yield Gitaly::ResolveConflictsRequest.new(files_json: chunk)
          end
        end

        response = GitalyClient.call(@repository.storage, :conflicts_service, :resolve_conflicts, req_enum, remote_storage: target_repository.storage)

        if response.resolution_error.present?
          raise Gitlab::Git::Conflict::Resolver::ResolutionError, response.resolution_error
        end
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

      def resolve_conflicts_request_header(target_repository, user, source_branch, target_branch, commit_message)
        Gitaly::ResolveConflictsRequestHeader.new(
          repository: @gitaly_repo,
          our_commit_oid: @our_commit_oid,
          target_repository: target_repository.gitaly_repository,
          their_commit_oid: @their_commit_oid,
          source_branch: source_branch,
          target_branch: target_branch,
          commit_message: commit_message,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly
        )
      end
    end
  end
end
