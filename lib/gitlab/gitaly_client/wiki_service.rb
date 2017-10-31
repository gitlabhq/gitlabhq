require 'stringio'

module Gitlab
  module GitalyClient
    class WikiService
      MAX_MSG_SIZE = 128.kilobytes.freeze

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def write_page(name, format, content, commit_details)
        request = Gitaly::WikiWritePageRequest.new(
          repository: @gitaly_repo,
          name: GitalyClient.encode(name),
          format: format.to_s,
          commit_details: Gitaly::WikiCommitDetails.new(
            name: GitalyClient.encode(commit_details.name),
            email: GitalyClient.encode(commit_details.email),
            message: GitalyClient.encode(commit_details.message)
          )
        )

        strio = StringIO.new(content)

        enum = Enumerator.new do |y|
          until strio.eof?
            chunk = strio.read(MAX_MSG_SIZE)
            request.content = GitalyClient.encode(chunk)

            y.yield request

            request = Gitaly::WikiWritePageRequest.new
          end
        end

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_write_page, enum)
        if error = response.duplicate_error.presence
          raise Gitlab::Git::Wiki::DuplicatePageError, error
        end
      end
    end
  end
end
