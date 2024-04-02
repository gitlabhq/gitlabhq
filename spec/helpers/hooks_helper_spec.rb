# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HooksHelper do
  let(:project) { build_stubbed(:project) }
  let(:project_hook) { build_stubbed(:project_hook, project: project) }
  let(:service_hook) { build_stubbed(:service_hook, integration: build_stubbed(:drone_ci_integration)) }
  let(:system_hook) { build_stubbed(:system_hook) }

  describe '#webhook_form_data' do
    subject { helper.webhook_form_data(project_hook) }

    context 'when there are no URL variables' do
      it 'returns proper data' do
        expect(subject).to match(
          url: project_hook.url,
          url_variables: "[]",
          custom_headers: "[]"
        )
      end
    end

    context 'when there are URL variables' do
      let(:project_hook) { build_stubbed(:project_hook, :url_variables, project: project) }

      it 'returns proper data' do
        expect(subject).to match(
          url: project_hook.url,
          url_variables: Gitlab::Json.dump([{ key: 'abc' }, { key: 'def' }]),
          custom_headers: "[]"
        )
      end
    end

    context 'when there are custom headers' do
      let(:project_hook) { build_stubbed(:project_hook, project: project, custom_headers: { test: 'blub' }) }

      it 'returns proper data' do
        expect(subject).to match(
          url: project_hook.url,
          url_variables: "[]",
          custom_headers: Gitlab::Json.dump([{ key: 'test', value: WebHook::SECRET_MASK }])
        )
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
