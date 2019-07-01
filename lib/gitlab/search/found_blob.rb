# frozen_string_literal: true

module Gitlab
  module Search
    class FoundBlob
      include EncodingHelper
      include Presentable
      include BlobLanguageFromGitAttributes
      include Gitlab::Utils::StrongMemoize

      attr_reader :project, :content_match, :blob_filename

      FILENAME_REGEXP = /\A(?<ref>[^:]*):(?<filename>[^\x00]*)\x00/.freeze
      CONTENT_REGEXP = /^(?<ref>[^:]*):(?<filename>[^\x00]*)\x00(?<startline>\d+)\x00/.freeze

      def self.preload_blobs(blobs)
        to_fetch = blobs.select { |blob| blob.is_a?(self) && blob.blob_filename }

        to_fetch.each { |blob| blob.fetch_blob }
      end

      def initialize(opts = {})
        @id = opts.fetch(:id, nil)
        @binary_filename = opts.fetch(:filename, nil)
        @binary_basename = opts.fetch(:basename, nil)
        @ref = opts.fetch(:ref, nil)
        @startline = opts.fetch(:startline, nil)
        @binary_data = opts.fetch(:data, nil)
        @per_page = opts.fetch(:per_page, 20)
        @project = opts.fetch(:project, nil)
        # Some callers (e.g. Elasticsearch) do not have the Project object,
        # yet they can trigger many calls in one go,
        # causing duplicated queries.
        # Allow those to just pass project_id instead.
        @project_id = opts.fetch(:project_id, nil)
        @content_match = opts.fetch(:content_match, nil)
        @blob_filename = opts.fetch(:blob_filename, nil)
        @repository = opts.fetch(:repository, nil)
      end

      def id
        @id ||= parsed_content[:id]
      end

      def ref
        @ref ||= parsed_content[:ref]
      end

      def startline
        @startline ||= parsed_content[:startline]
      end

      # binary_filename is used for running filters on all matches,
      # for grepped results (which use content_match), we get
      # filename from the beginning of the grepped result which is faster
      # then parsing whole snippet
      def binary_filename
        @binary_filename ||= content_match ? search_result_filename : parsed_content[:binary_filename]
      end

      def filename
        @filename ||= encode_utf8(@binary_filename || parsed_content[:binary_filename])
      end

      def basename
        @basename ||= encode_utf8(@binary_basename || parsed_content[:binary_basename])
      end

      def data
        @data ||= encode_utf8(@binary_data || parsed_content[:binary_data])
      end

      def path
        filename
      end

      def project_id
        @project_id || @project&.id
      end

      def present
        super(presenter_class: BlobPresenter)
      end

      def fetch_blob
        path = [ref, blob_filename]
        missing_blob = { binary_filename: blob_filename }

        BatchLoader.for(path).batch(default_value: missing_blob) do |refs, loader|
          Gitlab::Git::Blob.batch(repository, refs, blob_size_limit: 1024).each do |blob|
            # if the blob couldn't be fetched for some reason,
            # show at least the blob filename
            data = {
              id: blob.id,
              binary_filename: blob.path,
              binary_basename: path_without_extension(blob.path),
              ref: ref,
              startline: 1,
              binary_data: blob.data,
              project: project
            }

            loader.call([ref, blob.path], data)
          end
        end
      end

      private

      def search_result_filename
        content_match.match(FILENAME_REGEXP) { |matches| matches[:filename] }
      end

      def path_without_extension(path)
        Pathname.new(path).sub_ext('').to_s
      end

      def parsed_content
        strong_memoize(:parsed_content) do
          if content_match
            parse_search_result
          elsif blob_filename
            fetch_blob
          else
            {}
          end
        end
      end

      def parse_search_result
        ref = nil
        filename = nil
        basename = nil

        data = []
        startline = 0

        content_match.each_line.each_with_index do |line, index|
          prefix ||= line.match(CONTENT_REGEXP)&.tap do |matches|
            ref = matches[:ref]
            filename = matches[:filename]
            startline = matches[:startline]
            startline = startline.to_i - index
            basename = path_without_extension(filename)
          end

          data << line.sub(prefix.to_s, '')
        end

        {
          binary_filename: filename,
          binary_basename: basename,
          ref: ref,
          startline: startline,
          binary_data: data.join,
          project: project
        }
      end

      def repository
        @repository ||= project.repository
      end
    end
  end
end
