# frozen_string_literal: true

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

        strio = binary_io(content)

        enum = Enumerator.new do |y|
          until strio.eof?
            request.content = strio.read(MAX_MSG_SIZE)

            y.yield request

            request = Gitaly::WikiWritePageRequest.new
          end
        end

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_write_page, enum, timeout: GitalyClient.medium_timeout)
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

        strio = binary_io(content)

        enum = Enumerator.new do |y|
          until strio.eof?
            request.content = strio.read(MAX_MSG_SIZE)

            y.yield request

            request = Gitaly::WikiUpdatePageRequest.new
          end
        end

        GitalyClient.call(@repository.storage, :wiki_service, :wiki_update_page, enum, timeout: GitalyClient.medium_timeout)
      end

      def find_page(title:, version: nil, dir: nil)
        request = Gitaly::WikiFindPageRequest.new(
          repository: @gitaly_repo,
          title: encode_binary(title),
          revision: encode_binary(version),
          directory: encode_binary(dir)
        )

        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_find_page, request, timeout: GitalyClient.fast_timeout)

        wiki_page_from_iterator(response)
      end

      def list_all_pages(limit: 0, sort: nil, direction_desc: false)
        sort_value = Gitaly::WikiListPagesRequest::SortBy.resolve(sort.to_s.upcase.to_sym)

        params = { repository: @gitaly_repo, limit: limit, direction_desc: direction_desc }
        params[:sort] = sort_value if sort_value

        request = Gitaly::WikiListPagesRequest.new(params)
        stream = GitalyClient.call(@repository.storage, :wiki_service, :wiki_list_pages, request, timeout: GitalyClient.medium_timeout)
        stream.each_with_object([]) do |message, pages|
          page = message.page

          next unless page

          wiki_page = GitalyClient::WikiPage.new(page.to_h)
          version = new_wiki_page_version(page.version)

          pages << [wiki_page, version]
        end
      end

      def load_all_pages(limit: 0, sort: nil, direction_desc: false)
        sort_value = Gitaly::WikiGetAllPagesRequest::SortBy.resolve(sort.to_s.upcase.to_sym)

        params = { repository: @gitaly_repo, limit: limit, direction_desc: direction_desc }
        params[:sort] = sort_value if sort_value

        request = Gitaly::WikiGetAllPagesRequest.new(params)
        response = GitalyClient.call(@repository.storage, :wiki_service, :wiki_get_all_pages, request, timeout: GitalyClient.medium_timeout)

        pages = []

        loop do
          page, version = wiki_page_from_iterator(response) { |message| message.end_of_page }

          break unless page && version

          pages << [page, version]
        end

        pages
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
          user_id: commit_details.user_id,
          user_name: encode_binary(commit_details.username),
          name: encode_binary(commit_details.name),
          email: encode_binary(commit_details.email),
          message: encode_binary(commit_details.message)
        )
      end
    end
  end
end
