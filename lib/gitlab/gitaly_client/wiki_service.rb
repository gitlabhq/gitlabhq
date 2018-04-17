require 'stringio'

module Gitlab
  module GitalyClient
    class WikiService
      include Gitlab::EncodingHelper

      MAX_MSG_SIZE = 128.kilobytes.freeze

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def write_page(name, format, content, commit_details)
        request = Gitaly::WikiWritePageRequest.new(
          repository: @gitaly_repo,
          name: encode_binary(name),
          format: format.to_s,
          commit_details: gitaly_commit_details(commit_details)
        )

        strio = binary_stringio(content)

        enum = Enumerator.new do |y|
          until strio.eof?
            request.content = strio.read(MAX_MSG_SIZE)

            y.yield request

            request = Gitaly::WikiWritePageRequest.new
          end
        end

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_write_page, enum)
        if error = response.duplicate_error.presence
          raise Gitlab::Git::Wiki::DuplicatePageError, error
        end
      end

      def update_page(page_path, title, format, content, commit_details)
        request = Gitaly::WikiUpdatePageRequest.new(
          repository: @gitaly_repo,
          page_path: encode_binary(page_path),
          title: encode_binary(title),
          format: format.to_s,
          commit_details: gitaly_commit_details(commit_details)
        )

        strio = binary_stringio(content)

        enum = Enumerator.new do |y|
          until strio.eof?
            request.content = strio.read(MAX_MSG_SIZE)

            y.yield request

            request = Gitaly::WikiUpdatePageRequest.new
          end
        end

        GitalyClient.call(@repository.storage, :wiki_service, :wiki_update_page, enum)
      end

      def delete_page(page_path, commit_details)
        request = Gitaly::WikiDeletePageRequest.new(
          repository: @gitaly_repo,
          page_path: encode_binary(page_path),
          commit_details: gitaly_commit_details(commit_details)
        )

        GitalyClient.call(@repository.storage, :wiki_service, :wiki_delete_page, request)
      end

      def find_page(title:, version: nil, dir: nil)
        request = Gitaly::WikiFindPageRequest.new(
          repository: @gitaly_repo,
          title: encode_binary(title),
          revision: encode_binary(version),
          directory: encode_binary(dir)
        )

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_find_page, request)

        wiki_page_from_iterator(response)
      end

      def get_all_pages
        request = Gitaly::WikiGetAllPagesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_get_all_pages, request)
        pages = []

        loop do
          page, version = wiki_page_from_iterator(response) { |message| message.end_of_page }

          break unless page && version

          pages << [page, version]
        end

        pages
      end

      # options:
      #  :page     - The Integer page number.
      #  :per_page - The number of items per page.
      #  :limit    - Total number of items to return.
      def page_versions(page_path, options)
        request = Gitaly::WikiGetPageVersionsRequest.new(
          repository: @gitaly_repo,
          page_path: encode_binary(page_path),
          page: options[:page] || 1,
          per_page: options[:per_page] || Gollum::Page.per_page
        )

        stream = GitalyClient.call(@repository.storage, :wiki_service, :wiki_get_page_versions, request)

        versions = []
        stream.each do |message|
          message.versions.each do |version|
            versions << new_wiki_page_version(version)
          end
        end

        versions
      end

      def find_file(name, revision)
        request = Gitaly::WikiFindFileRequest.new(
          repository: @gitaly_repo,
          name: encode_binary(name),
          revision: encode_binary(revision)
        )

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_find_file, request)
        wiki_file = nil

        response.each do |message|
          next unless message.name.present? || wiki_file

          if wiki_file
            wiki_file.raw_data << message.raw_data
          else
            wiki_file = GitalyClient::WikiFile.new(message.to_h)
            # All gRPC strings in a response are frozen, so we get
            # an unfrozen version here so appending in the else clause below doesn't blow up.
            wiki_file.raw_data = wiki_file.raw_data.dup
          end
        end

        wiki_file
      end

      def get_formatted_data(title:, dir: nil, version: nil)
        request = Gitaly::WikiGetFormattedDataRequest.new(
          repository: @gitaly_repo,
          title: encode_binary(title),
          revision: encode_binary(version),
          directory: encode_binary(dir)
        )

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_get_formatted_data, request)
        response.reduce("") { |memo, msg| memo << msg.data }
      end

      private

      # If a block is given and the yielded value is truthy, iteration will be
      # stopped early at that point; else the iterator is consumed entirely.
      # The iterator is traversed with `next` to allow resuming the iteration.
      def wiki_page_from_iterator(iterator)
        wiki_page = version = nil

        while message = iterator.next
          break if block_given? && yield(message)

          page = message.page
          next unless page

          if wiki_page
            wiki_page.raw_data << page.raw_data
          else
            wiki_page = GitalyClient::WikiPage.new(page.to_h)

            version = new_wiki_page_version(page.version)
          end
        end

        [wiki_page, version]
      rescue StopIteration
        [wiki_page, version]
      end

      def new_wiki_page_version(version)
        Gitlab::Git::WikiPageVersion.new(
          Gitlab::Git::Commit.decorate(@repository, version.commit),
          version.format
        )
      end

      def gitaly_commit_details(commit_details)
        Gitaly::WikiCommitDetails.new(
          name: encode_binary(commit_details.name),
          email: encode_binary(commit_details.email),
          message: encode_binary(commit_details.message)
        )
      end
    end
  end
end
