# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings > CI/CD settings' do
  let(:project) { create(:project_empty_repo) }
  let(:user) { create(:user) }
  let(:role) { :maintainer }

  context 'Deploy tokens' do
    let!(:deploy_token) { create(:deploy_token, projects: [project]) }

    before do
      project.add_role(user, role)
      sign_in(user)
      stub_container_registry_config(enabled: true)
      visit project_settings_ci_cd_path(project)
    end

    it_behaves_like 'a deploy token in ci/cd settings' do
      let(:entity_type) { 'project' }
    end
  end
end
