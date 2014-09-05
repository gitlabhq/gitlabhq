module Gitlab
  class SnippetSearchResults < SearchResults
    attr_reader :limit_snippet_ids

    def initialize(limit_snippet_ids, query)
      @limit_snippet_ids = limit_snippet_ids
      @query = query
    end

    def objects(scope, page = nil)
      case scope
      when 'snippet_titles'
        Kaminari.paginate_array(snippet_titles).page(page).per(per_page)
      when 'snippet_blobs'
        Kaminari.paginate_array(snippet_blobs).page(page).per(per_page)
      else
        super
      end
    end

    def total_count
      @total_count ||= snippet_titles_count + snippet_blobs_count
    end

    def snippet_titles_count
      @snippet_titles_count ||= snippet_titles.count
    end

    def snippet_blobs_count
      @snippet_blobs_count ||= snippet_blobs.count
    end

    private

    def snippet_titles
      Snippet.where(id: limit_snippet_ids).search(query).order('updated_at DESC')
    end

    def snippet_blobs
      search = Snippet.where(id: limit_snippet_ids).search_code(query)
      search = search.order('updated_at DESC').to_a
      snippets = []
      search.each { |e| snippets << chunk_snippet(e) }
      snippets
    end

    def default_scope
      'snippet_blobs'
    end

    # Get an array of line numbers surrounding a matching
    # line, bounded by min/max.
    #
    # @returns Array of line numbers
    def bounded_line_numbers(line, min, max)
      lower = line - surrounding_lines > min ? line - surrounding_lines : min
      upper = line + surrounding_lines < max ? line + surrounding_lines : max
      (lower..upper).to_a
    end

    # Returns a sorted set of lines to be included in a snippet preview.
    # This ensures matching adjacent lines do not display duplicated
    # surrounding code.
    #
    # @returns Array, unique and sorted.
    def matching_lines(lined_content)
      used_lines = []
      lined_content.each_with_index do |line, line_number|
        used_lines.concat bounded_line_numbers(
          line_number,
          0,
          lined_content.size
        ) if line.include?(query)
      end

      used_lines.uniq.sort
    end

    # 'Chunkify' entire snippet.  Splits the snippet data into matching lines +
    # surrounding_lines() worth of unmatching lines.
    #
    # @returns a hash with {snippet_object, snippet_chunks:{data,start_line}}
    def chunk_snippet(snippet)
      lined_content = snippet.content.split("\n")
      used_lines = matching_lines(lined_content)

      snippet_chunk = []
      snippet_chunks = []
      snippet_start_line = 0
      last_line = -1

      # Go through each used line, and add consecutive lines as a single chunk
      # to the snippet chunk array.
      used_lines.each do |line_number|
        if last_line < 0
          # Start a new chunk.
          snippet_start_line = line_number
          snippet_chunk << lined_content[line_number]
        elsif last_line == line_number - 1
          # Consecutive line, continue chunk.
          snippet_chunk << lined_content[line_number]
        else
          # Non-consecutive line, add chunk to chunk array.
          snippet_chunks << {
            data: snippet_chunk.join("\n"),
            start_line: snippet_start_line + 1
          }

          # Start a new chunk.
          snippet_chunk = [lined_content[line_number]]
          snippet_start_line = line_number
        end
        last_line = line_number
      end
      # Add final chunk to chunk array
      snippet_chunks << {
        data: snippet_chunk.join("\n"),
        start_line: snippet_start_line + 1
      }

      # Return snippet with chunk array
      { snippet_object: snippet, snippet_chunks: snippet_chunks }
    end

    # Defines how many unmatching lines should be
    # included around the matching lines in a snippet
    def surrounding_lines
      3
    end
  end
end
