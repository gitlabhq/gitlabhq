# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches project settings', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace, pages_https_only: false) }

  before do
    sign_in(user)
  end

  context 'in general settings page' do
    before do
      visit edit_project_path(project)
    end

    it_behaves_like 'can search settings', 'Naming', 'Visibility'
  end

  context 'in Integrations page' do
    before do
      visit project_settings_integrations_path(project)
    end

    it_behaves_like 'can highlight results', 'third-party applications'
  end

  context 'in access tokens page' do
    before do
      visit project_settings_access_tokens_path(project)
    end

    it_behaves_like 'can highlight results', 'Token name'
  end

  context 'in Repository page' do
    before do
      visit project_settings_repository_path(project)
    end

    it_behaves_like 'can search settings', 'Deploy keys', 'Mirroring repositories'
  end

  context 'in CI/CD page' do
    before do
      visit project_settings_ci_cd_path(project)
    end

    it_behaves_like 'can search settings', 'General pipelines', 'Auto DevOps'
  end

  context 'in Operations page' do
    before do
      visit project_settings_operations_path(project)
    end

    it_behaves_like 'can search settings', 'Alerts', 'Error tracking'
  end
end
