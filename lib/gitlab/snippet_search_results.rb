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
      matching_snippets = Snippet.where(id: limit_snippet_ids).search_code(query).order('updated_at DESC')
      matching_snippets = matching_snippets.to_a
      snippets = []
      matching_snippets.each { |e| snippets << chunk_snippet(e) }
      snippets
    end

    def default_scope
      'snippet_blobs'
    end

    def bounded_line_numbers(line, min, max, surrounding_lines)
      lower = line - surrounding_lines > min ? line - surrounding_lines : min
      upper = line + surrounding_lines < max ? line + surrounding_lines : max
      (lower..upper).to_a
    end

    def chunk_snippet(snippet)
      surrounding_lines = 3
      used_lines = []
      lined_content = snippet.content.split("\n")
      lined_content.each_with_index { |line, line_number|
        used_lines.concat bounded_line_numbers(
          line_number,
          0,
          lined_content.size,
          surrounding_lines
        ) if line.include?(query)
      }

      used_lines = used_lines.uniq.sort

      snippet_chunk = []
      snippet_chunks = []
      snippet_start_line = 0
      last_line = -1
      used_lines.each { |line_number|
        if last_line < 0
          snippet_start_line = line_number
          snippet_chunk << lined_content[line_number]
        elsif last_line == line_number - 1
          snippet_chunk << lined_content[line_number]
        else
          snippet_chunks << {
            data: snippet_chunk.join("\n"),
            start_line: snippet_start_line + 1
          }
          snippet_chunk = [lined_content[line_number]]
          snippet_start_line = line_number
        end
        last_line = line_number
      }
      snippet_chunks << {
        data: snippet_chunk.join("\n"),
        start_line: snippet_start_line + 1
      }

      { snippet_object: snippet, snippet_chunks: snippet_chunks }
    end
  end
end
