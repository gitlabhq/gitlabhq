# frozen_string_literal: true

module HooksHelper
  def webhook_form_data(hook)
    {
      name: hook.name,
      description: hook.description,
      secret_token: hook.masked_token, # always use masked_token to avoid exposing secret_token to frontend
      url: hook.url,
      url_variables: Gitlab::Json.dump(hook.url_variables.keys.map { { key: _1 } }),
      custom_headers: Gitlab::Json.dump(hook.custom_headers.keys.map { { key: _1, value: WebHook::SECRET_MASK } }),
      is_new_hook: hook.new_record?.to_s,
      triggers: Gitlab::Json.dump(all_triggers(hook))
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

  private

  def all_triggers(hook)
    triggers = hook.class.triggers.values.index_with do |event_type|
      # rubocop:disable GitlabSecurity/PublicSend -- event_type comes from triggers constant, not user input
      hook.public_send(event_type)
      # rubocop:enable GitlabSecurity/PublicSend
    end

    branch_filter_settings = {
      push_events_branch_filter: hook.push_events_branch_filter,
      branch_filter_strategy: hook.branch_filter_strategy
    }

    triggers.merge(branch_filter_settings)
  end
end

HooksHelper.prepend_mod_with('HooksHelper')
