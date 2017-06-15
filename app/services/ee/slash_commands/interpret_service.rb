module EE
  module SlashCommands
    module InterpretService
      include ::Gitlab::SlashCommands::Dsl

      desc 'Change assignee(s)'
      explanation do
        'Change assignee(s)'
      end
      params '@user1 @user2'
      condition do
        issuable.allows_multiple_assignees? &&
          issuable.persisted? &&
          issuable.assignees.any? &&
          current_user.can?(:"admin_#{issuable.to_ability_name}", project)
      end
      command :reassign do |unassign_param|
        @updates[:assignee_ids] = extract_users(unassign_param).map(&:id)
      end
    end
  end
end
