# frozen_string_literal: true

# This class finds files in a repository by name and content
# the result is joined and sorted by file name
module Gitlab
  class FileFinder
    attr_reader :project, :ref

    delegate :repository, to: :project

    def initialize(project, ref)
      @project = project
      @ref = ref
    end

    def find(query, content_match_cutoff: nil)
      query = Gitlab::Search::Query.new(query, encode_binary: true) do
        filter :filename, matcher: ->(filter, blob) { blob.binary_path =~ /#{filter[:regex_value]}$/i }
        filter :path, matcher: ->(filter, blob) { blob.binary_path =~ /#{filter[:regex_value]}/i }
        filter :extension, matcher: ->(filter, blob) { blob.binary_path =~ /\.#{filter[:regex_value]}$/i }
      end

      content_match_cutoff = nil if query.filters.any?
      files = find_by_path(query.term) + find_by_content(query.term, { limit: content_match_cutoff })

      files = query.filter_results(files) if query.filters.any?

      files
    end

    private

    def find_by_content(query, options)
      repository.search_files_by_content(query, ref, options).map do |result|
        Gitlab::Search::FoundBlob.new(content_match: result, project: project, ref: ref, repository: repository)
      end
    end

    def find_by_path(query)
      search_paths(query).map do |path|
        Gitlab::Search::FoundBlob.new(blob_path: path, path: path, project: project, ref: ref, repository: repository)
      end
    end

    # Overridden in Gitlab::WikiFileFinder
    def search_paths(query)
      repository.search_files_by_name(query, ref)
    end
  end
end
