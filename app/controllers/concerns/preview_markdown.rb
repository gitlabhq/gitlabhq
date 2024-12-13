# frozen_string_literal: true

module PreviewMarkdown
  extend ActiveSupport::Concern

  def preview_markdown
    result = PreviewMarkdownService.new(
      container: resource_parent,
      current_user: current_user,
      params: markdown_service_params
    ).execute

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

  def resource_parent
    @project
  end

  def projects_filter_params
    {
      issuable_reference_expansion_enabled: true,
      suggestions_filter_enabled: params[:preview_suggestions].present?
    }
  end

  def timeline_events_filter_params
    {
      issuable_reference_expansion_enabled: true,
      pipeline: :'incident_management/timeline_event'
    }
  end

  def wikis_filter_params
    {
      pipeline: :wiki,
      wiki: wiki,
      page_slug: params[:id],
      repository: wiki.repository,
      issuable_reference_expansion_enabled: true
    }
  end

  def markdown_service_params
    params
  end

  def markdown_context_params
    case controller_name
    when 'wikis'
      wiki_page = wiki.find_page(params[:id])

      wikis_filter_params
    when 'snippets'        then { skip_project_check: true }
    when 'groups'          then { group: group, issuable_reference_expansion_enabled: true }
    when 'projects'        then projects_filter_params
    when 'timeline_events' then timeline_events_filter_params
    when 'organizations'   then { pipeline: :description }
    else {}
    end.merge(
      requested_path: params[:path] || wiki_page&.path,
      ref: params[:ref],
      # Disable comments in markdown for IE browsers because comments in IE
      # could allow script execution.
      allow_comments: !browser.ie?
    )
  end
end
