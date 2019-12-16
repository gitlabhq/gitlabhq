# frozen_string_literal: true

module HooksHelper
  def link_to_test_hook(hook, trigger)
    path = test_hook_path(hook, trigger)
    trigger_human_name = trigger.to_s.tr('_', ' ').camelize

    link_to path, rel: 'nofollow', method: :post do
      content_tag(:span, trigger_human_name)
    end
  end

  def test_hook_path(hook, trigger)
    case hook
    when ProjectHook
      test_project_hook_path(hook.project, hook, trigger: trigger)
    when SystemHook
      test_admin_hook_path(hook, trigger: trigger)
    end
  end

  def edit_hook_path(hook)
    case hook
    when ProjectHook
      edit_project_hook_path(hook.project, hook)
    when SystemHook
      edit_admin_hook_path(hook)
    end
  end

  def destroy_hook_path(hook)
    case hook
    when ProjectHook
      project_hook_path(hook.project, hook)
    when SystemHook
      admin_hook_path(hook)
    end
  end
end

HooksHelper.prepend_if_ee('EE::HooksHelper')
