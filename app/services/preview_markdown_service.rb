class PreviewMarkdownService < BaseService
  def execute
    text, commands = explain_slash_commands(params[:text])
    users = find_user_references(text)

    success(
      text: text,
      users: users,
      commands: commands.join(' ')
    )
  end

  private

  def explain_slash_commands(text)
    return text, [] unless %w(Issue MergeRequest).include?(commands_target_type)

    slash_commands_service = SlashCommands::InterpretService.new(project, current_user)
    slash_commands_service.explain(text, find_commands_target)
  end

  def find_user_references(text)
    extractor = Gitlab::ReferenceExtractor.new(project, current_user)
    extractor.analyze(text, author: current_user)
    extractor.users.map(&:username)
  end

  def find_commands_target
    if commands_target_id.present?
      finder = commands_target_type == 'Issue' ? IssuesFinder : MergeRequestsFinder
      finder.new(current_user, project_id: project.id).find(commands_target_id)
    else
      collection = commands_target_type == 'Issue' ? project.issues : project.merge_requests
      collection.build
    end
  end

  def commands_target_type
    params[:slash_commands_target_type]
  end

  def commands_target_id
    params[:slash_commands_target_id]
  end
end
