require 'spec_helper'

describe HooksHelper do
  let(:project) { create(:project) }
  let(:project_hook) { create(:project_hook, project: project) }
  let(:system_hook) { create(:system_hook) }
  let(:trigger) { 'push_events' }

  describe '#link_to_test_hook' do
    it 'returns project namespaced link' do
      expect(helper.link_to_test_hook(project_hook, trigger))
        .to include("href=\"#{test_project_hook_path(project, project_hook, trigger: trigger)}\"")
    end

    it 'returns admin namespaced link' do
      expect(helper.link_to_test_hook(system_hook, trigger))
        .to include("href=\"#{test_admin_hook_path(system_hook, trigger: trigger)}\"")
    end
  end
end
