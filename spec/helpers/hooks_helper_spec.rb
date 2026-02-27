# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HooksHelper, feature_category: :integrations do
  let(:project) { build_stubbed(:project) }
  let(:project_hook) { build_stubbed(:project_hook, project: project) }
  let(:service_hook) { build_stubbed(:service_hook, integration: build_stubbed(:drone_ci_integration)) }
  let(:system_hook) { build_stubbed(:system_hook) }

  let(:expected_triggers) do
    triggers = project_hook.class.triggers.values.index_with do |event_type|
      project_hook.public_send(event_type)
    end

    branch_filter_settings = {
      push_events_branch_filter: project_hook.push_events_branch_filter,
      branch_filter_strategy: project_hook.branch_filter_strategy
    }

    Gitlab::Json.dump(triggers.merge(branch_filter_settings))
  end

  describe '#webhook_form_data' do
    subject(:form_data) { helper.webhook_form_data(project_hook) }

    context 'when there are no URL variables' do
      before do
        stub_feature_flags(project_deploy_token_expiring_notifications: false)
      end

      it 'returns proper data' do
        expect(form_data).to match(
          name: project_hook.name,
          description: project_hook.description,
          secret_token: nil,
          url: project_hook.url,
          url_variables: "[]",
          custom_headers: "[]",
          is_new_hook: "false",
          triggers: expected_triggers,
          deploy_token_events_enabled: 'false'
        )
      end
    end

    context 'when there are URL variables' do
      let(:project_hook) { build_stubbed(:project_hook, :url_variables, :token, project: project) }

      before do
        stub_feature_flags(project_deploy_token_expiring_notifications: false)
      end

      it 'returns proper data' do
        expect(form_data).to match(
          name: project_hook.name,
          description: project_hook.description,
          secret_token: WebHook::SECRET_MASK,
          url: project_hook.url,
          url_variables: Gitlab::Json.dump([{ key: 'abc' }, { key: 'def' }]),
          custom_headers: "[]",
          is_new_hook: "false",
          triggers: expected_triggers,
          deploy_token_events_enabled: 'false'
        )
      end
    end

    context 'when there are custom headers' do
      let(:project_hook) { build_stubbed(:project_hook, :token, project: project, custom_headers: { test: 'blub' }) }

      before do
        stub_feature_flags(project_deploy_token_expiring_notifications: false)
      end

      it 'returns proper data' do
        expect(form_data).to match(
          name: project_hook.name,
          description: project_hook.description,
          secret_token: WebHook::SECRET_MASK,
          url: project_hook.url,
          url_variables: "[]",
          custom_headers: Gitlab::Json.dump([{ key: 'test', value: WebHook::SECRET_MASK }]),
          is_new_hook: "false",
          triggers: expected_triggers,
          deploy_token_events_enabled: 'false'
        )
      end
    end

    context 'when project hook with feature flag enabled' do
      before do
        stub_feature_flags(project_deploy_token_expiring_notifications: true)
      end

      it 'includes deploy_token_events_enabled as true' do
        expect(form_data).to include(deploy_token_events_enabled: 'true')
      end
    end

    context 'when project hook with feature flag disabled' do
      before do
        stub_feature_flags(project_deploy_token_expiring_notifications: false)
      end

      it 'includes deploy_token_events_enabled as false' do
        expect(form_data).to include(deploy_token_events_enabled: 'false')
      end
    end

    context 'when hook is not a project hook' do
      subject(:form_data) { helper.webhook_form_data(system_hook) }

      it 'does not include deploy_token_events_enabled' do
        expect(form_data).not_to have_key(:deploy_token_events_enabled)
      end
    end

    context 'when project hook has no project association' do
      let(:project_hook_without_project) { build_stubbed(:project_hook, project: nil) }

      subject(:form_data) { helper.webhook_form_data(project_hook_without_project) }

      it 'does not include deploy_token_events_enabled' do
        expect(form_data).not_to have_key(:deploy_token_events_enabled)
      end
    end
  end

  describe '#webhook_test_items' do
    let(:triggers) { [:push_events, :note_events] }

    it 'returns test items for disclosure' do
      expect(helper.webhook_test_items(project_hook, triggers)).to eq([
        {
          href: test_hook_path(project_hook, triggers[0]),
          text: 'Push events'
        },
        {
          href: test_hook_path(project_hook, triggers[1]),
          text: 'Comments'
        }
      ])
    end
  end

  describe '#test_hook_path' do
    let(:trigger) { 'push_events' }

    it 'returns project namespaced link' do
      expect(helper.test_hook_path(project_hook, trigger))
        .to eq(test_project_hook_path(project, project_hook, trigger: trigger))
    end

    it 'returns admin namespaced link' do
      expect(helper.test_hook_path(system_hook, trigger))
        .to eq(test_admin_hook_path(system_hook, trigger: trigger))
    end
  end

  describe '#hook_log_path' do
    context 'with a project hook' do
      let(:web_hook_log) { build_stubbed(:web_hook_log, web_hook: project_hook) }

      it 'returns project-namespaced link' do
        expect(helper.hook_log_path(project_hook, web_hook_log))
          .to eq(web_hook_log.present.details_path)
      end
    end

    context 'with a service hook' do
      let(:web_hook_log) { build_stubbed(:web_hook_log, web_hook: service_hook) }

      it 'returns project-namespaced link' do
        expect(helper.hook_log_path(project_hook, web_hook_log))
          .to eq(web_hook_log.present.details_path)
      end
    end

    context 'with a system hook' do
      let(:web_hook_log) { build_stubbed(:web_hook_log, web_hook: system_hook) }

      it 'returns admin-namespaced link' do
        expect(helper.hook_log_path(system_hook, web_hook_log))
          .to eq(admin_hook_hook_log_path(system_hook, web_hook_log))
      end
    end
  end
end
