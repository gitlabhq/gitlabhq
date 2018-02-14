FactoryBot.define do
  factory :audit_event, aliases: [:user_audit_event] do
    user
    type 'SecurityEvent'

    entity_type 'User'
    entity_id   { user.id }

    trait :project_event do
      entity_type 'Project'
      entity_id   { create(:project).id }
    end

    trait :group_event do
      entity_type 'Group'
      entity_id   { create(:group).id }
    end

    factory :project_audit_event, traits: [:project_event]
    factory :group_audit_event, traits: [:group_event]
  end
end
