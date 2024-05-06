# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User transfers a project', :js, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:group) { create(:group) }

  before do
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(120)

    group.add_owner(user)
    sign_in(user)
  end

  def transfer_project(project, group, confirm: true)
    visit edit_project_path(project)

    page.within('.js-project-transfer-form') do
      find_by_testid('transfer-project-namespace').click
    end

    within_testid('transfer-project-namespace') do
      page.find("li button", text: group.full_name).click
    end

    click_button('Transfer project')

    return unless confirm

    fill_in 'confirm_name_input', with: project.name

    click_button 'Confirm'

    wait_for_requests
  end

  it 'focuses on the confirmation field' do
    transfer_project(project, group, confirm: false)
    expect(page).to have_selector '#confirm_name_input:focus'
  end

  it 'allows transferring a project to a group' do
    old_path = project_path(project)
    transfer_project(project, group)
    new_path = namespace_project_path(group, project)

    expect(project.reload.namespace).to eq(group)

    visit new_path
    wait_for_requests

    expect(page).to have_current_path(new_path, ignore_query: true)
    expect(find_by_testid('breadcrumb-links')).to have_content(project.name)

    visit old_path
    wait_for_requests

    expect(page).to have_current_path(new_path, ignore_query: true)
    expect(find_by_testid('breadcrumb-links')).to have_content(project.name)
  end

  context 'and a new project is added with the same path' do
    it 'overrides the redirect' do
      old_path = project_path(project)
      project_path = project.path
      transfer_project(project, group)
      new_project = create(:project, namespace: user.namespace, path: project_path)
      visit old_path

      expect(page).to have_current_path(old_path, ignore_query: true)
      expect(find_by_testid('breadcrumb-links')).to have_content(new_project.name)
    end
  end

  context 'when nested groups are available' do
    it 'allows transferring a project to a subgroup' do
      subgroup = create(:group, parent: group)

      transfer_project(project, subgroup)

      expect(project.reload.namespace).to eq(subgroup)
    end
  end
end
