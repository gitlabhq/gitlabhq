# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project group variables', :js, feature_category: :secrets_management do
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

  shared_examples 'renders the haml column headers' do
    it "shows inherited CI variables table with correct columns" do
      page.within('.inherited-ci-variable-table') do
        columns = find_all('th')

        expect(columns[0].text).to eq('Key')
        expect(columns[1].text).to eq('Environments')
        expect(columns[2].text).to eq('Group')
      end
    end
  end

  shared_examples 'renders the vue app column headers' do
    it "shows inherited CI variables table with correct columns" do
      page.within('[data-testid="inherited-ci-variable-table"]') do
        # Wait for vue app to load
        wait_for_requests

        columns = find_all('[role=columnheader]')

        expect(columns[0].text).to eq('Key')
        expect(columns[1].text).to eq('Attributes')
        expect(columns[2].text).to eq('Environments')
        expect(columns[3].text).to eq('Group')
      end
    end
  end

  context 'when feature flag ci_vueify_inherited_group_variables is disabled' do
    before do
      stub_feature_flags(ci_vueify_inherited_group_variables: false)
    end

    describe 'project in group' do
      before do
        visit project_path
      end

      it_behaves_like 'renders the haml column headers'

      it 'shows inherited variable info from ancestor group' do
        visit project_path

        expect(page).to have_content(key1)
        expect(page).to have_content(group.name)
      end
    end

    describe 'project in subgroup' do
      before do
        visit project2_path
      end

      it_behaves_like 'renders the haml column headers'

      it 'shows inherited variable info from all ancestor groups' do
        visit project2_path

        expect(page).to have_content(key1)
        expect(page).to have_content(key2)
        expect(page).to have_content(group.name)
        expect(page).to have_content(subgroup.name)
      end
    end

    describe 'project in nested subgroup' do
      before do
        visit project3_path
      end

      it_behaves_like 'renders the haml column headers'

      it 'shows inherited variable info from all ancestor groups' do
        visit project3_path

        expect(page).to have_content(key1)
        expect(page).to have_content(key2)
        expect(page).to have_content(key3)
        expect(page).to have_content(group.name)
        expect(page).to have_content(subgroup.name)
        expect(page).to have_content(subgroup_nested.name)
      end
    end

    it 'project origin keys link to ancestor groups ci_cd settings' do
      visit project_path

      find('.group-origin-link').click

      wait_for_requests

      page.within('[data-testid="ci-variable-table"]') do
        expect(find('.js-ci-variable-row:nth-child(1) [data-label="Key"]').text).to eq(key1)
      end
    end
  end

  context 'when feature flag ci_vueify_inherited_group_variables is enabled' do
    before do
      stub_feature_flags(ci_vueify_inherited_group_variables: true)
    end

    describe 'project in group' do
      before do
        visit project_path
      end

      it_behaves_like 'renders the vue app column headers'

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

      it_behaves_like 'renders the vue app column headers'

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

      it_behaves_like 'renders the vue app column headers'

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
end
