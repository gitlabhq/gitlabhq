# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches project settings', :js do
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

  context 'in Webhooks page' do
    before do
      visit project_hooks_path(project)
    end

    it_behaves_like 'can highlight results', 'Secret token'
  end

  context 'in Access Tokens page' do
    before do
      visit project_settings_access_tokens_path(project)
    end

    it_behaves_like 'can highlight results', 'Expiration date'
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

  context 'in Pages page' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)

      visit project_pages_path(project)
    end

    it_behaves_like 'can highlight results', 'static website'
  end
end
