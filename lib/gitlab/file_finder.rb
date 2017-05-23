# This class finds files in a repository by name and content
# the result is joined and sorted by file name
module Gitlab
  class FileFinder
    BATCH_SIZE = 100

    attr_reader :project, :ref

    def initialize(project, ref)
      @project = project
      @ref = ref
    end

    def find(query)
      blobs = project.repository.search_files_by_content(query, ref).first(BATCH_SIZE)
      found_file_names = Set.new

      results = blobs.map do |blob|
        blob = Gitlab::ProjectSearchResults.parse_search_result(blob)
        found_file_names << blob.filename

        [blob.filename, blob]
      end

      project.repository.search_files_by_name(query, ref).first(BATCH_SIZE).each do |filename|
        results << [filename, OpenStruct.new(ref: ref)] unless found_file_names.include?(filename)
      end

      results.sort_by(&:first)
    end
  end
end
