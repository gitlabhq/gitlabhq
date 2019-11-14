# frozen_string_literal: true

module PreviewMarkdown
  extend ActiveSupport::Concern

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def preview_markdown
    result = PreviewMarkdownService.new(@project, current_user, markdown_service_params).execute

    render json: {
      body: view_context.markdown(result[:text], markdown_context_params),
      references: {
        users: result[:users],
        suggestions: SuggestionSerializer.new.represent_diff(result[:suggestions]),
        commands: view_context.markdown(result[:commands])
      }
    }
  end

  private

  def projects_filter_params
    {
      issuable_state_filter_enabled: true,
      suggestions_filter_enabled: params[:preview_suggestions].present?
    }
  end

  def markdown_service_params
    params
  end

  def markdown_context_params
    case controller_name
    when 'wikis'    then { pipeline: :wiki, project_wiki: @project_wiki, page_slug: params[:id] }
    when 'snippets' then { skip_project_check: true }
    when 'groups'   then { group: group }
    when 'projects' then projects_filter_params
    else {}
    end.merge(requested_path: params[:path])
  end

  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
