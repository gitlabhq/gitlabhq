module Search
  class SnippetService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      query = params[:search]
      query = Shellwords.shellescape(query) if query.present?
      return result unless query.present?
      snippets = Snippet.accessible_to(current_user)

      page_size = 20
      result_limit = 500
      if params[:search_code]
        matching_snippets = snippets.search_code(query)
        matching_snippets = matching_snippets.order('updated_at DESC')
        matching_snippets = matching_snippets.limit(result_limit).to_a
        snippets = []
        matching_snippets.each { |e| snippets << chunk_snippet(e, query) }

        paginated_chunked_snippets = Kaminari.
          paginate_array(snippets).page(params[:page]).per(page_size)
        result[:snippets] = paginated_chunked_snippets
        result[:total_results] = paginated_chunked_snippets.total_count
      else
        snippets_array = snippets.search(query).order('updated_at DESC').to_a
        result[:snippets] = Kaminari.paginate_array(snippets_array).
          page(params[:page]).per(page_size)
        result[:total_results] = snippets_array.size
      end

      result
    end

    protected

    def bounded_line_numbers(line, min, max, surrounding_lines)
      lower = line - surrounding_lines > min ? line - surrounding_lines : min
      upper = line + surrounding_lines < max ? line + surrounding_lines : max
      (lower..upper).to_a
    end

    def result
      @result ||= {
        snippets: [],
        total_results: 0
      }
    end

    def chunk_snippet(snippet, query)
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
