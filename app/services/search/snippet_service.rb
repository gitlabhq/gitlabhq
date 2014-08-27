module Search
  class SnippetService
    require 'set'

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
        surrounding_lines = 3
        matching_snippets = snippets.search_code(query)
        matching_snippets = matching_snippets.order('updated_at DESC').limit(result_limit).to_a
        matching_snippets.each_with_index { |blob, blob_index|
          used_lines = SortedSet.new
          lined_content = blob.content.split("\n")
          lined_content.each_with_index { |line, line_number|
            if line.include?(query)
              for i in 0..surrounding_lines
                used_lines << line_number - i unless line_number - i < 0
                used_lines << line_number + i unless line_number + i >= lined_content.size
              end
            end
          }

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
                :data => snippet_chunk.join("\n"),
                :start_line => snippet_start_line + 1
              }
              snippet_chunk = [lined_content[line_number]]
              snippet_start_line = line_number
            end
            last_line = line_number
          }
          snippet_chunks << {
            :data => snippet_chunk.join("\n"),
            :start_line => snippet_start_line + 1
          }
          matching_snippets[blob_index] = {
            :snippet_object => blob,
            :snippet_chunks => snippet_chunks
          }
        }

        paginated_matching_snippets = Kaminari.paginate_array(matching_snippets).page(params[:page]).per(page_size)
        result[:snippets] = paginated_matching_snippets
        result[:total_results] = paginated_matching_snippets.total_count
      else
        snippets_array = snippets.search(query).order('updated_at DESC').to_a
        result[:snippets] = Kaminari.paginate_array(snippets_array).page(params[:page]).per(page_size)
        result[:total_results] = snippets_array.size
      end

      result
    end

    def result
      @result ||= {
        snippets: [],
        total_results: 0
      }
    end
  end
end
