# frozen_string_literal: true

module Projects
  class LsifDataService
    attr_reader :file, :project, :commit_id, :docs,
      :doc_ranges, :ranges, :def_refs, :hover_refs

    CACHE_EXPIRE_IN = 1.hour

    def initialize(file, project, commit_id)
      @file = file
      @project = project
      @commit_id = commit_id

      fetch_data!
    end

    def execute(path)
      doc_id = find_doc_id(docs, path)
      dir_absolute_path = docs[doc_id]&.delete_suffix(path)

      doc_ranges[doc_id]&.map do |range_id|
        location, ref_id = ranges[range_id].values_at('loc', 'ref_id')
        line_data, column_data = location

        {
          start_line: line_data.first,
          end_line: line_data.last,
          start_char: column_data.first,
          end_char: column_data.last,
          definition_url: definition_url_for(def_refs[ref_id], dir_absolute_path),
          hover: highlighted_hover(hover_refs[ref_id])
        }
      end
    end

    private

    def fetch_data
      Rails.cache.fetch("project:#{project.id}:lsif:#{commit_id}", expires_in: CACHE_EXPIRE_IN) do
        data = nil

        file.open do |stream|
          Zlib::GzipReader.wrap(stream) do |gz_stream|
            data = Gitlab::Json.parse(gz_stream.read)
          end
        end

        data
      end
    end

    def fetch_data!
      data = fetch_data

      @docs = data['docs']
      @doc_ranges = data['doc_ranges']
      @ranges = data['ranges']
      @def_refs = data['def_refs']
      @hover_refs = data['hover_refs']
    end

    def find_doc_id(docs, path)
      docs.reduce(nil) do |doc_id, (id, doc_path)|
        next doc_id unless doc_path =~ /#{path}$/

        if doc_id.nil? || docs[doc_id].size > doc_path.size
          doc_id = id
        end

        doc_id
      end
    end

    def definition_url_for(ref_id, dir_absolute_path)
      return unless range = ranges[ref_id]

      def_doc_id, location = range.values_at('doc_id', 'loc')
      localized_doc_url = docs[def_doc_id].delete_prefix(dir_absolute_path)

      # location is stored as [[start_line, end_line], [start_char, end_char]]
      start_line = location.first.first

      line_anchor = "L#{start_line + 1}"
      definition_ref_path = [commit_id, localized_doc_url].join('/')

      Gitlab::Routing.url_helpers.project_blob_path(project, definition_ref_path, anchor: line_anchor)
    end

    def highlighted_hover(hovers)
      hovers&.map do |hover|
        # Documentation for a method which is added as comments on top of the method
        # is stored as a raw string value in LSIF file
        next { value: hover } unless hover.is_a?(Hash)

        value = Gitlab::Highlight.highlight(nil, hover['value'], language: hover['language'])
        { language: hover['language'], value: value }
      end
    end
  end
end
