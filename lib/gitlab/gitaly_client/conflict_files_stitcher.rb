# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class ConflictFilesStitcher
      include Enumerable

      attr_reader :gitaly_repo

      def initialize(rpc_response, gitaly_repo)
        @rpc_response = rpc_response
        @gitaly_repo = gitaly_repo
      end

      def each
        current_file = nil

        @rpc_response.each do |msg|
          msg.files.each do |gitaly_file|
            if gitaly_file.header
              yield current_file if current_file

              current_file = file_from_gitaly_header(gitaly_file.header)
            else
              current_file.raw_content = "#{current_file.raw_content}#{gitaly_file.content}"
            end
          end
        end

        yield current_file if current_file
      end

      private

      def file_from_gitaly_header(header)
        Gitlab::Git::Conflict::File.new(
          Gitlab::GitalyClient::Util.git_repository(gitaly_repo),
          header.commit_oid,
          conflict_from_gitaly_file_header(header),
          ''
        )
      end

      def conflict_from_gitaly_file_header(header)
        {
          ancestor: { path: encode_path(header.ancestor_path) },
          ours: { path: encode_path(header.our_path), mode: header.our_mode },
          theirs: { path: encode_path(header.their_path) }
        }
      end

      def encode_path(path)
        Gitlab::EncodingHelper.encode_utf8(path)
      end
    end
  end
end
