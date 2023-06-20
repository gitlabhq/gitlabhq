# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches group settings', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'in general settings page' do
    before do
      visit edit_group_path(group)
    end

    it_behaves_like 'can search settings', 'Naming', 'Permissions'
  end

  context 'in Integrations page' do
    before do
      visit group_settings_integrations_path(group)
    end

    it_behaves_like 'can highlight results', 'Group-level integration management'
  end

  context 'in Repository page' do
    before do
      visit group_settings_repository_path(group)
    end

    it_behaves_like 'can search settings', 'Deploy tokens', 'Default branch'
  end

  context 'in CI/CD page' do
    before do
      visit group_settings_ci_cd_path(group)
    end

    it_behaves_like 'can search settings', 'Variables', 'Auto DevOps'
  end

  context 'in Packages and registries page' do
    before do
      visit group_settings_packages_and_registries_path(group)
    end

    it_behaves_like 'can highlight results', 'Allow packages with the same name and version'
  end
end
