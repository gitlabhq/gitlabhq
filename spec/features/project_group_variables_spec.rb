# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project group variables', :js do
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
  let!(:ci_variable) { create(:ci_group_variable, group: group, key: key1) }
  let!(:ci_variable2) { create(:ci_group_variable, group: subgroup, key: key2) }
  let!(:ci_variable3) { create(:ci_group_variable, group: subgroup_nested, key: key3) }
  let(:project_path) { project_settings_ci_cd_path(project) }
  let(:project2_path) { project_settings_ci_cd_path(project2) }
  let(:project3_path) { project_settings_ci_cd_path(project3) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    group.add_owner(user)
  end

  it 'project in group shows inherited vars from ancestor group' do
    visit project_path
    expect(page).to have_content(key1)
    expect(page).to have_content(group.name)
  end

  it 'project in subgroup shows inherited vars from all ancestor groups' do
    visit project2_path
    expect(page).to have_content(key1)
    expect(page).to have_content(key2)
    expect(page).to have_content(group.name)
    expect(page).to have_content(subgroup.name)
  end

  it 'project in nested subgroup shows inherited vars from all ancestor groups' do
    visit project3_path
    expect(page).to have_content(key1)
    expect(page).to have_content(key2)
    expect(page).to have_content(key3)
    expect(page).to have_content(group.name)
    expect(page).to have_content(subgroup.name)
    expect(page).to have_content(subgroup_nested.name)
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
