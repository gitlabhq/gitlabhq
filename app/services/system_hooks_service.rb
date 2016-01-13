class SystemHooksService
  def execute_hooks_for(model, event)
    execute_hooks(build_event_data(model, event))
  end

  private

  def execute_hooks(data)
    SystemHook.all.each do |sh|
      async_execute_hook(sh, data, 'system_hooks')
    end
  end

  def async_execute_hook(hook, data, hook_name)
    Sidekiq::Client.enqueue(SystemHookWorker, hook.id, data, hook_name)
  end

  def build_event_data(model, event)
    data = {
      event_name: build_event_name(model, event),
      created_at: model.created_at.xmlschema,
      updated_at: model.updated_at.xmlschema
    }

    case model
    when Key
      data.merge!(
        key: model.key,
        id: model.id
      )
      if model.user
        data.merge!(
          username: model.user.username
        )
      end
    when Project
      data.merge!(project_data(model))

      if event == :rename || event == :transfer
        data.merge!({
          old_path_with_namespace: model.old_path_with_namespace
        })
      end

      data
    when User
      data.merge!({
        name: model.name,
        email: model.email,
        user_id: model.id,
        username: model.username
      })
    when ProjectMember
      data.merge!(project_member_data(model))
    when Group
      owner = model.owner

      data.merge!(
        name: model.name,
        path: model.path,
        group_id: model.id,
        owner_name: owner.respond_to?(:name) ? owner.name : nil,
        owner_email: owner.respond_to?(:email) ? owner.email : nil,
      )
    when GroupMember
      data.merge!(group_member_data(model))
    end
  end

  def build_event_name(model, event)
    case model
    when ProjectMember
      return "user_add_to_team"      if event == :create
      return "user_remove_from_team" if event == :destroy
    when GroupMember
      return 'user_add_to_group'      if event == :create
      return 'user_remove_from_group' if event == :destroy
    else
      "#{model.class.name.downcase}_#{event.to_s}"
    end
  end

  def project_data(model)
    owner = model.owner

    {
      name: model.name,
      path: model.path,
      path_with_namespace: model.path_with_namespace,
      project_id: model.id,
      owner_name: owner.name,
      owner_email: owner.respond_to?(:email) ?  owner.email : "",
      project_visibility: Project.visibility_levels.key(model.visibility_level_field).downcase
    }
  end

  def project_member_data(model)
    {
      project_name: model.project.name,
      project_path: model.project.path,
      project_path_with_namespace: model.project.path_with_namespace,
      project_id: model.project.id,
      user_username: model.user.username,
      user_name: model.user.name,
      user_email: model.user.email,
      user_id: model.user.id,
      access_level: model.human_access,
      project_visibility: Project.visibility_levels.key(model.project.visibility_level_field).downcase
    }
  end

  def group_member_data(model)
    {
      group_name: model.group.name,
      group_path: model.group.path,
      group_id: model.group.id,
      user_username: model.user.username,
      user_name: model.user.name,
      user_email: model.user.email,
      user_id: model.user.id,
      group_access: model.human_access,
    }
  end
end
