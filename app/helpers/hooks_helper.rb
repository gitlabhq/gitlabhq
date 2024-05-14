# frozen_string_literal: true

module HooksHelper
  def webhook_form_data(hook)
    {
      url: hook.url,
      url_variables: Gitlab::Json.dump(hook.url_variables.keys.map { { key: _1 } }),
      custom_headers: Gitlab::Json.dump(hook.custom_headers.keys.map { { key: _1, value: WebHook::SECRET_MASK } })
    }
  end

  def webhook_test_items(hook, triggers)
    triggers.map do |trigger|
      {
        href: test_hook_path(hook, trigger),
        text: integration_webhook_event_human_name(trigger)
      }
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

  def hook_log_path(hook, hook_log)
    case hook
    when ProjectHook, ServiceHook
      hook_log.present.details_path
    when SystemHook
      admin_hook_hook_log_path(hook, hook_log)
    end
  end
end

HooksHelper.prepend_mod_with('HooksHelper')
