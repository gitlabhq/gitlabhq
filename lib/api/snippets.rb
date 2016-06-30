module API
  # Issues API
  class Snippets < Grape::API
    before { authenticate! }

    resource :snippets do
      # Get all global snippets
      #
      # Example Request:
      #   GET /snippets
      get do
        present paginate(current_user.snippets), with: Entities::Snippet
      end

      # Get a global snippet
      #
      # Parameters:
      #   snippet_id (required) - The ID of a global snippet
      # Example Request:
      #   GET /snippets/:snippet_id
      get ":snippet_id" do
        @snippet = current_user.snippets.find(params[:snippet_id])
        present @snippet, with: Entities::Snippet
      end

      # Create a new global snippet
      #
      # Parameters:
      #   title (required) - The title of a snippet
      #   file_name (required) - The name of a snippet file
      #   code (required) - The content of a snippet
      #   visibility_level (required) - The snippet's visibility
      # Example Request:
      #   POST /snippets
      post do
        required_attributes! [:title, :file_name, :code, :visibility_level]

        attrs = attributes_for_keys [:title, :file_name, :visibility_level]
        attrs[:content] = params[:code] if params[:code].present?
        @snippet = CreateSnippetService.new(nil, current_user,
                                            attrs).execute

        if @snippet.errors.any?
          render_validation_error!(@snippet)
        else
          present @snippet, with: Entities::Snippet
        end
      end

      # Update an existing global snippet
      #
      # Parameters:
      #   snippet_id (required) - The ID of a global snippet
      #   title (optional) - The title of a snippet
      #   file_name (optional) - The name of a snippet file
      #   code (optional) - The content of a snippet
      #   visibility_level (optional) - The snippet's visibility
      # Example Request:
      #   PUT /snippets/:snippet_id
      put ":snippet_id" do
        @snippet = current_user.snippets.find(params[:snippet_id])

        attrs = attributes_for_keys [:title, :file_name, :visibility_level]
        attrs[:content] = params[:code] if params[:code].present?

        UpdateSnippetService.new(nil, current_user, @snippet,
                                 attrs).execute
        if @snippet.errors.any?
          render_validation_error!(@snippet)
        else
          present @snippet, with: Entities::Snippet
        end
      end

      # Delete a global snippet
      #
      # Parameters:
      #   snippet_id (required) - The ID of a global snippet
      # Example Request:
      #   DELETE /snippets/:snippet_id
      delete ":snippet_id" do
        begin
          @snippet = current_user.snippets.find(params[:snippet_id])
          @snippet.destroy
        rescue
          not_found!('Snippet')
        end
      end

      # Get a raw global snippet
      #
      # Parameters:
      #   snippet_id (required) - The ID of a global snippet
      # Example Request:
      #   GET /snippets/:snippet_id/raw
      get ":snippet_id/raw" do
        @snippet = current_user.snippets.find(params[:snippet_id])

        env['api.format'] = :txt
        content_type 'text/plain'
        present @snippet.content
      end
    end
  end
end
