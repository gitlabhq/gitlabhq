module EE
  module QuickActions
    module InterpretService
      include ::Gitlab::QuickActions::Dsl

      desc 'Change assignee(s)'
      explanation do
        'Change assignee(s)'
      end
      params '@user1 @user2'
      condition do
        issuable.is_a?(::Issuable) &&
          issuable.allows_multiple_assignees? &&
          issuable.persisted? &&
          current_user.can?(:"admin_#{issuable.to_ability_name}", project)
      end
      command :reassign do |reassign_param|
        @updates[:assignee_ids] = extract_users(reassign_param).map(&:id)
      end

      desc 'Set weight'
      explanation do |weight|
        "Sets weight to #{weight}." if weight
      end
      params "0, 1, 2, …"
      condition do
        issuable.is_a?(::Issuable) &&
          issuable.supports_weight? &&
          current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
      end
      parse_params do |weight|
        weight.to_i if weight.to_i > 0
      end
      command :weight do |weight|
        @updates[:weight] = weight if weight
      end

      desc 'Clear weight'
      explanation 'Clears weight.'
      condition do
        issuable.is_a?(::Issuable) &&
          issuable.persisted? &&
          issuable.supports_weight? &&
          issuable.weight? &&
          current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
      end
      command :clear_weight do
        @updates[:weight] = nil
      end
    end
  end
end
