require 'spec_helper'

feature 'User transfers a project', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    sign_in user
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

  it 'allows transferring a project to a subgroup of a namespace' do
    group = create(:group)
    group.add_owner(user)

    transfer_project(project, group)

    expect(project.reload.namespace).to eq(group)
  end

  context 'when nested groups are available', :nested_groups do
    it 'allows transferring a project to a subgroup' do
      parent = create(:group)
      parent.add_owner(user)
      subgroup = create(:group, parent: parent)

      transfer_project(project, subgroup)

      expect(project.reload.namespace).to eq(subgroup)
    end
  end
end
