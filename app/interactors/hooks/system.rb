module Hooks
  class System < Hooks::Base
    def setup
      context.fail!(message: 'Invalid entity') if context[:entity].blank?
      context.fail!(message: 'Invalid event') if context[:event].blank?

      context[:event_data] = build_event_data(context[:entity], context[:event])
    end

    def perform
      execute_hooks(context[:event_data])
    end

    def rollback
      context.delete(:event_data)
    end

    private

    def execute_hooks(data)
      SystemHook.all.each do |sh|
        async_execute_hook sh, data
      end
    end

    def async_execute_hook(hook, data)
      Sidekiq::Client.enqueue(SystemHookWorker, hook.id, data)
    end

    def build_event_data(entity, event)
      data = {
        event_name: build_event_name(entity, event),
        created_at: entity.created_at
      }

      case entity
      when Project
        owner = entity.owner

        data.merge!({
          name: entity.name,
          path: entity.path,
          path_with_namespace: entity.path_with_namespace,
          project_id: entity.id,
          owner_name: owner.name,
          owner_email: owner.respond_to?(:email) ?  owner.email : nil,
          project_visibility: Project.visibility_levels.key(entity.visibility_level_field).downcase
        })
      when User
        data.merge!({
          name: entity.name,
          email: entity.email,
          user_id: entity.id
        })
      when UsersProject
        data.merge!({
          project_name: entity.project.name,
          project_path: entity.project.path,
          project_id: entity.project_id,
          user_name: entity.user.name,
          user_email: entity.user.email,
          project_access: entity.human_access,
          project_visibility: Project.visibility_levels.key(entity.project.visibility_level_field).downcase
        })
      end
    end

    def build_event_name(entity, event)
      case entity
      when UsersProject
        return "user_add_to_team"      if event == :create
        return "user_remove_from_team" if event == :destroy
      else
        "#{entity.class.name.downcase}_#{event.to_s}"
      end
    end
  end
end
