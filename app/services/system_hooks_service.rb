# frozen_string_literal: true

class SystemHooksService
  def execute_hooks_for(model, event)
    data = build_event_data(model, event)

    model.run_after_commit_or_now do
      SystemHooksService.new.execute_hooks(data)
    end
  end

  def execute_hooks(data, hooks_scope = :all)
    SystemHook.executable.hooks_for(hooks_scope).find_each do |hook|
      hook.async_execute(data, 'system_hooks')
    end

    Gitlab::FileHook.execute_all_async(data)
  end

  private

  def build_event_data(model, event)
    builder_class = case model
                    when GroupMember
                      Gitlab::HookData::GroupMemberBuilder
                    when Group
                      Gitlab::HookData::GroupBuilder
                    when ProjectMember
                      Gitlab::HookData::ProjectMemberBuilder
                    when User
                      Gitlab::HookData::UserBuilder
                    when Project
                      Gitlab::HookData::ProjectBuilder
                    when Key
                      Gitlab::HookData::KeyBuilder
                    end

    builder = builder_class.new(model)

    if builder_class == Gitlab::HookData::ProjectBuilder
      builder.build(event, include_deprecated_owner: true)
    else
      builder.build(event)
    end
  end
end
