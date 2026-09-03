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

  it 'schedules an async transfer and shows the transfer banner' do
    transfer_project(project, group)

    expect(page).to have_current_path(edit_project_path(project))
    expect(page).to have_content(s_(
      'TransferProject|This project is scheduled for transfer. ' \
        'Users with the Maintainer or Owner role will be notified when the transfer succeeds or fails.'
    ))
    expect(project.project_namespace.reload.state).to eq('transfer_scheduled')
  end

  context 'when nested groups are available' do
    it 'schedules an async transfer to a subgroup' do
      subgroup = create(:group, parent: group)

      transfer_project(project, subgroup)

      expect(page).to have_current_path(edit_project_path(project))
      expect(project.project_namespace.reload.state).to eq('transfer_scheduled')
    end
  end
end
