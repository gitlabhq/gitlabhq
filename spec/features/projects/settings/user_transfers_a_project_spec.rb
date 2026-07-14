# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User transfers a project', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before_all do
    group.add_owner(user)
  end

  before do
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(120)
    stub_feature_flags(groups_and_projects_async_transfer: false)

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

    fill_in 'confirm_name_input', with: project.full_path

    click_button 'Confirm'
  end

  it 'focuses on the confirmation field' do
    transfer_project(project, group, confirm: false)
    expect(page).to have_selector '#confirm_name_input:focus'
  end

  it 'allows transferring a project to a group' do
    old_path = project_path(project)
    transfer_project(project, group)
    new_path = namespace_project_path(group, project)

    expect(page).to have_current_path(edit_namespace_project_path(group, project))
    expect(project.reload.namespace).to eq(group)

    visit new_path

    expect(page).to have_current_path(new_path, ignore_query: true)
    expect(find_by_testid('breadcrumb-links')).to have_content(project.name)

    visit old_path

    expect(page).to have_current_path(new_path, ignore_query: true)
    expect(find_by_testid('breadcrumb-links')).to have_content(project.name)
  end

  context 'and a new project is added with the same path' do
    it 'overrides the redirect' do
      old_path = project_path(project)
      project_path = project.path
      transfer_project(project, group)

      # Wait for the transfer to complete (redirect to the new path) before creating
      # the new project. Otherwise the test thread can race ahead of the server thread
      # and reuse `project_path` while the original project's route still occupies it,
      # making the new project invalid and producing a misleading members source_id error.
      expect(page).to have_current_path(edit_namespace_project_path(group, project))

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

      expect(page).to have_current_path(edit_namespace_project_path(subgroup, project))
      expect(project.reload.namespace).to eq(subgroup)
    end
  end

  context 'when groups_and_projects_async_transfer is enabled' do
    before do
      stub_feature_flags(groups_and_projects_async_transfer: true)

      transfer_project(project, group)
    end

    it 'shows async transfer banner' do
      expect(page).to have_content(s_(
        'TransferProject|This project is scheduled for transfer. ' \
          'Users with the Maintainer or Owner role will be notified when the transfer succeeds or fails.'
      ))
    end
  end
end
