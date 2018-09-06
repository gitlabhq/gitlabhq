# frozen_string_literal: true

class PreviewMarkdownService < BaseService
  def execute
    text, commands = explain_quick_actions(params[:text])
    users = find_user_references(text)

    success(
      text: text,
      users: users,
      commands: commands.join(' '),
      markdown_engine: markdown_engine
    )
  end

  private

  def explain_quick_actions(text)
    return text, [] unless %w(Issue MergeRequest Commit).include?(commands_target_type)

    quick_actions_service = QuickActions::InterpretService.new(project, current_user)
    quick_actions_service.explain(text, find_commands_target)
  end

  def find_user_references(text)
    extractor = Gitlab::ReferenceExtractor.new(project, current_user)
    extractor.analyze(text, author: current_user)
    extractor.users.map(&:username)
  end

  def find_commands_target
    QuickActions::TargetService
      .new(project, current_user)
      .execute(commands_target_type, commands_target_id)
  end

  def commands_target_type
    params[:quick_actions_target_type]
  end

  def commands_target_id
    params[:quick_actions_target_id]
  end

  def markdown_engine
    if params[:legacy_render]
      :redcarpet
    else
      CacheMarkdownField::MarkdownEngine.from_version(params[:markdown_version].to_i)
    end
  end
end
