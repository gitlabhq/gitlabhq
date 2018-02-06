module Gitlab
  module GitalyClient
    class ConflictFilesStitcher
      include Enumerable

      def initialize(rpc_response)
        @rpc_response = rpc_response
      end

      def each
        current_file = nil

        @rpc_response.each do |msg|
          msg.files.each do |gitaly_file|
            if gitaly_file.header
              yield current_file if current_file

              current_file = file_from_gitaly_header(gitaly_file.header)
            else
              current_file.content << gitaly_file.content
            end
          end
        end

        yield current_file if current_file
      end

      private

      def file_from_gitaly_header(header)
        Gitlab::Git::Conflict::File.new(
          Gitlab::GitalyClient::Util.git_repository(header.repository),
          header.commit_oid,
          conflict_from_gitaly_file_header(header),
          ''
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
