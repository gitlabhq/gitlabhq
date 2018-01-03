module PreviewMarkdown
  extend ActiveSupport::Concern

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def preview_markdown
    result = PreviewMarkdownService.new(@project, current_user, params).execute

    markdown_params =
      case controller_name
      when 'wikis'    then { pipeline: :wiki, project_wiki: @project_wiki, page_slug: params[:id] }
      when 'snippets' then { skip_project_check: true }
      when 'groups'   then { group: group }
      else {}
      end

    format = params[:format]

    formatted_text =
      case format
      when 'rdoc'
        view_context.rdoc(result[:text], markdown_params)
      when 'asciidoc'
        view_context.asciidoc(result[:text], markdown_params)
      else
        view_context.markdown(result[:text], markdown_params)
      end

    render json: {
      body: formatted_text,
      references: {
        users: result[:users],
        commands: view_context.markdown(result[:commands])
      }
    }
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
