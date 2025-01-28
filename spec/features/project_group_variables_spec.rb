# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project group variables', :js, feature_category: :ci_variables do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:subgroup) { create(:group, parent: group) }
  let(:subgroup_nested) { create(:group, parent: subgroup) }
  let(:project) { create(:project, group: group) }
  let(:project2) { create(:project, group: subgroup) }
  let(:project3) { create(:project, group: subgroup_nested) }
  let(:key1) { 'test_key' }
  let(:key2) { 'test_key2' }
  let(:key3) { 'test_key3' }
  let(:env1) { 'test_env' }
  let(:env2) { 'test_env2' }
  let(:env3) { 'test_env3' }
  let(:attributes1) { 'Expanded' }
  let(:attributes2) { 'Protected' }
  let(:attributes3) { 'Masked' }
  let!(:ci_variable) { create(:ci_group_variable, group: group, key: key1, environment_scope: env1) }

  let!(:ci_variable2) do
    create(:ci_group_variable, group: subgroup, key: key2, environment_scope: env2, protected: true, raw: true)
  end

  let!(:ci_variable3) do
    create(:ci_group_variable, group: subgroup_nested, key: key3, environment_scope: env3, masked: true, raw: true)
  end

  let(:project_path) { project_settings_ci_cd_path(project) }
  let(:project2_path) { project_settings_ci_cd_path(project2) }
  let(:project3_path) { project_settings_ci_cd_path(project3) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    group.add_owner(user)
  end

  shared_examples 'renders correct column headers' do
    it "shows inherited CI variables table with correct columns" do
      within_testid('inherited-ci-variable-table') do
        # Wait for vue app to load
        wait_for_requests

        columns = find_all('[role=columnheader]')

        expect(columns[0].text).to eq('Key')
        expect(columns[1].text).to eq('Environments')
        expect(columns[2].text).to eq('Group')
      end
    end
  end

  describe 'project in group' do
    before do
      visit project_path
    end

    it_behaves_like 'renders correct column headers'

    it 'shows inherited variable info from ancestor group' do
      expect(page).to have_content(key1)
      expect(page).to have_content(attributes1)
      expect(page).to have_content(group.name)
    end
  end

  describe 'project in subgroup' do
    before do
      visit project2_path
    end

    it_behaves_like 'renders correct column headers'

    it 'shows inherited variable info from all ancestor groups' do
      expect(page).to have_content(key1)
      expect(page).to have_content(key2)
      expect(page).to have_content(attributes1)
      expect(page).to have_content(attributes2)
      expect(page).to have_content(group.name)
      expect(page).to have_content(subgroup.name)
    end
  end

  describe 'project in nested subgroup' do
    before do
      visit project3_path
    end

    it_behaves_like 'renders correct column headers'

    it 'shows inherited variable info from all ancestor groups' do
      expect(page).to have_content(key1)
      expect(page).to have_content(key2)
      expect(page).to have_content(key3)
      expect(page).to have_content(attributes1)
      expect(page).to have_content(attributes2)
      expect(page).to have_content(attributes3)
      expect(page).to have_content(group.name)
      expect(page).to have_content(subgroup.name)
      expect(page).to have_content(subgroup_nested.name)
    end
  end
end
