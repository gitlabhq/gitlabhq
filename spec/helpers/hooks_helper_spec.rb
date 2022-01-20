# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HooksHelper do
  let(:project) { create(:project) }
  let(:project_hook) { create(:project_hook, project: project) }
  let(:service_hook) { create(:service_hook, integration: create(:drone_ci_integration)) }
  let(:system_hook) { create(:system_hook) }

  describe '#link_to_test_hook' do
    let(:trigger) { 'push_events' }

    it 'returns project namespaced link' do
      expect(helper.link_to_test_hook(project_hook, trigger))
        .to include("href=\"#{test_project_hook_path(project, project_hook, trigger: trigger)}\"")
    end

    it 'returns admin namespaced link' do
      expect(helper.link_to_test_hook(system_hook, trigger))
        .to include("href=\"#{test_admin_hook_path(system_hook, trigger: trigger)}\"")
    end
  end

  describe '#hook_log_path' do
    context 'with a project hook' do
      let(:web_hook_log) { create(:web_hook_log, web_hook: project_hook) }

      it 'returns project-namespaced link' do
        expect(helper.hook_log_path(project_hook, web_hook_log))
          .to eq(web_hook_log.present.details_path)
      end
    end

    context 'with a service hook' do
      let(:web_hook_log) { create(:web_hook_log, web_hook: service_hook) }

      it 'returns project-namespaced link' do
        expect(helper.hook_log_path(project_hook, web_hook_log))
          .to eq(web_hook_log.present.details_path)
      end
    end

    context 'with a system hook' do
      let(:web_hook_log) { create(:web_hook_log, web_hook: system_hook) }

      it 'returns admin-namespaced link' do
        expect(helper.hook_log_path(system_hook, web_hook_log))
          .to eq(admin_hook_hook_log_path(system_hook, web_hook_log))
      end
    end
  end
end
