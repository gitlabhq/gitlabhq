require 'spec_helper'

describe 'Projects > Settings > User transfers a project', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  def transfer_project(project, group)
    visit edit_project_path(project)

    page.within('.js-project-transfer-form') do
      page.find('.select2-container').click
    end

    page.find("div[role='option']", text: group.full_name).click

    click_button('Transfer project')

    fill_in 'confirm_name_input', with: project.name

    click_button 'Confirm'

    wait_for_requests
  end

  it 'allows transferring a project to a group' do
    old_path = project_path(project)
    transfer_project(project, group)
    new_path = namespace_project_path(group, project)

    expect(project.reload.namespace).to eq(group)

    visit new_path
    wait_for_requests

    expect(current_path).to eq(new_path)
    expect(find('.breadcrumbs')).to have_content(project.name)

    visit old_path
    wait_for_requests

    expect(current_path).to eq(new_path)
    expect(find('.breadcrumbs')).to have_content(project.name)
  end

  context 'and a new project is added with the same path' do
    it 'overrides the redirect' do
      old_path = project_path(project)
      project_path = project.path
      transfer_project(project, group)
      new_project = create(:project, namespace: user.namespace, path: project_path)
      visit old_path

      expect(current_path).to eq(old_path)
      expect(find('.breadcrumbs')).to have_content(new_project.name)
    end
  end

  context 'when nested groups are available', :nested_groups do
    it 'allows transferring a project to a subgroup' do
      subgroup = create(:group, parent: group)

      transfer_project(project, subgroup)

      expect(project.reload.namespace).to eq(subgroup)
    end
  end
end
