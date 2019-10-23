# frozen_string_literal: true

module PreviewMarkdown
  extend ActiveSupport::Concern

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def preview_markdown
    result = PreviewMarkdownService.new(@project, current_user, params).execute

    markdown_params =
      case controller_name
      when 'snippets' then { skip_project_check: true }
      when 'groups'   then { group: group }
      when 'projects' then projects_filter_params
      else preview_markdown_params
      end

    render json: {
      body: view_context.markdown(result[:text], markdown_params),
      references: {
        users: result[:users],
        suggestions: SuggestionSerializer.new.represent_diff(result[:suggestions]),
        commands: view_context.markdown(result[:commands])
      }
    }
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def projects_filter_params
    {
      issuable_state_filter_enabled: true,
      suggestions_filter_enabled: params[:preview_suggestions].present?
    }
  end

  private

  # Override this method to customise the markdown for your controller
  def preview_markdown_params
    {}
  end
end
