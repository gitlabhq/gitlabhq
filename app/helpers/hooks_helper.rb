module HooksHelper
  def link_to_test_hook(hook, trigger)
    path = case hook
           when ProjectHook
             project = hook.project
             test_project_hook_path(project, hook, trigger: trigger)
           when SystemHook
             test_admin_hook_path(hook, trigger: trigger)
           end

    trigger_human_name = trigger.to_s.tr('_', ' ').camelize

    link_to path, rel: 'nofollow' do
      content_tag(:span, trigger_human_name)
    end
  end
end
