# frozen_string_literal: true

FactoryBot.define do
  factory :audit_event, class: 'AuditEvent', aliases: [:user_audit_event] do
    user

    transient { target_user { association(:user) } }

    entity_type { 'User' }
    entity_id   { target_user.id }
    entity_path { target_user.full_path }
    target_details { target_user.name }
    ip_address { IPAddr.new '127.0.0.1' }
    author_name { 'Jane Doe' }
    details do
      {
        change: 'email address',
        from: 'admin@gitlab.com',
        to: 'maintainer@gitlab.com',
        author_name: user.name,
        target_id: target_user.id,
        target_type: 'User',
        target_details: target_user.name,
        ip_address: '127.0.0.1',
        entity_path: target_user.full_path
      }
    end

    trait :project_event do
      transient { target_project { association(:project) } }

      entity_type { 'Project' }
      entity_id   { target_project.id }
      entity_path { target_project.full_path }
      target_details { target_project.name }
      ip_address { IPAddr.new '127.0.0.1' }
      details do
        {
          change: 'packages_enabled',
          from: true,
          to: false,
          author_name: user.name,
          target_id: target_project.id,
          target_type: 'Project',
          target_details: target_project.name,
          ip_address: '127.0.0.1',
          entity_path: target_project.full_path
        }
      end
    end

    trait :unauthenticated do
      author_id { -1 }
      author_name { 'An unauthenticated user' }
      details do
        {
          custom_message: 'Custom action',
          author_name: 'An unauthenticated user',
          target_id: target_project.id,
          target_type: 'Project',
          target_details: target_project.name,
          ip_address: '127.0.0.1',
          entity_path: target_project.full_path
        }
      end
    end

    trait :group_event do
      transient { target_group { association(:group) } }

      entity_type { 'Group' }
      entity_id   { target_group.id }
      entity_path { target_group.full_path }
      target_details { target_group.name }
      ip_address { IPAddr.new '127.0.0.1' }
      details do
        {
          change: 'project_creation_level',
          from: nil,
          to: 'Developers + Maintainers',
          author_name: user.name,
          target_id: target_group.id,
          target_type: 'Group',
          target_details: target_group.name,
          ip_address: '127.0.0.1',
          entity_path: target_group.full_path
        }
      end
    end

    if Gitlab.ee?
      trait :instance_event do
        transient { instance_scope { Gitlab::Audit::InstanceScope.new } }

        entity_type { Gitlab::Audit::InstanceScope.name }
        entity_id   { instance_scope.id }
        entity_path { instance_scope.full_path }
        target_details { instance_scope.name }
        ip_address { IPAddr.new '127.0.0.1' }
        details do
          {
            change: 'project_creation_level',
            from: nil,
            to: 'Developers + Maintainers',
            author_name: user.name,
            target_id: instance_scope.id,
            target_type: Gitlab::Audit::InstanceScope.name,
            target_details: instance_scope.name,
            ip_address: '127.0.0.1',
            entity_path: instance_scope.full_path
          }
        end
      end

      factory :instance_audit_event, traits: [:instance_event]
    end

    factory :project_audit_event, traits: [:project_event]
    factory :group_audit_event, traits: [:group_event]
  end
end
