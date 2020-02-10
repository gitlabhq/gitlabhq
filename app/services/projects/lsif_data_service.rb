# frozen_string_literal: true

module Projects
  class LsifDataService
    attr_reader :file, :project, :path, :commit_id

    CACHE_EXPIRE_IN = 1.hour

    def initialize(file, project, params)
      @file = file
      @project = project
      @path = params[:path]
      @commit_id = params[:commit_id]
    end

    def execute
      docs, doc_ranges, ranges =
        fetch_data.values_at('docs', 'doc_ranges', 'ranges')

      doc_id = doc_id_from(docs)

      doc_ranges[doc_id]&.map do |range_id|
        line_data, column_data = ranges[range_id]['loc']

        {
          start_line: line_data.first,
          end_line: line_data.last,
          start_char: column_data.first,
          end_char: column_data.last
        }
      end
    end

    private

    def fetch_data
      Rails.cache.fetch("project:#{project.id}:lsif:#{commit_id}", expires_in: CACHE_EXPIRE_IN) do
        data = nil

        file.open do |stream|
          Zlib::GzipReader.wrap(stream) do |gz_stream|
            data = JSON.parse(gz_stream.read)
          end
        end

        data
      end
    end

    def doc_id_from(docs)
      docs.reduce(nil) do |doc_id, (id, doc_path)|
        next doc_id unless doc_path =~ /#{path}$/

        if doc_id.nil? || docs[doc_id].size > doc_path.size
          doc_id = id
        end

        doc_id
      end
    end
  end
end
