# This class finds files in a repository by name and content
# the result is joined and sorted by file name
module Gitlab
  class FileFinder
    BATCH_SIZE = 100

    attr_reader :project, :ref

    delegate :repository, to: :project

    def initialize(project, ref)
      @project = project
      @ref = ref
    end

    def find(query)
      by_content = find_by_content(query)

      already_found = Set.new(by_content.map(&:filename))
      by_filename = find_by_filename(query, except: already_found)

      (by_content + by_filename)
        .sort_by(&:filename)
        .map { |blob| [blob.filename, blob] }
    end

    private

    def find_by_content(query)
      results = repository.search_files_by_content(query, ref).first(BATCH_SIZE)
      results.map { |result| Gitlab::ProjectSearchResults.parse_search_result(result, project) }
    end

    def find_by_filename(query, except: [])
      filenames = repository.search_files_by_name(query, ref).first(BATCH_SIZE)
      filenames.delete_if { |filename| except.include?(filename) } unless except.empty?

      blob_refs = filenames.map { |filename| [ref, filename] }
      blobs = Gitlab::Git::Blob.batch(repository, blob_refs, blob_size_limit: 1024)

      blobs.map do |blob|
        Gitlab::SearchResults::FoundBlob.new(
          id: blob.id,
          filename: blob.path,
          basename: File.basename(blob.path),
          ref: ref,
          startline: 1,
          data: blob.data,
          project: project
        )
      end
    end
  end
end
