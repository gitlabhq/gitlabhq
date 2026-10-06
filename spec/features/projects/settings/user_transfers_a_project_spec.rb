# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User transfers a project', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:transfer_scheduled_message) do
    s_(
      'TransferProject|This project is scheduled for transfer. ' \
        'If the transfer fails, the user who started it receives a to-do item with the reason.'
    )
  end

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

  it 'schedules an async transfer and shows the transfer banner', :aggregate_failures do
    transfer_project(project, group)

    expect(page).to have_current_path(edit_project_path(project))
    expect(page).to have_content(transfer_scheduled_message)
    expect(project.project_namespace.reload.state).to eq('transfer_scheduled')
  end

  context 'when nested groups are available' do
    it 'schedules an async transfer to a subgroup', :aggregate_failures do
      subgroup = create(:group, parent: group)

      transfer_project(project, subgroup)

      expect(page).to have_current_path(edit_project_path(project))
      # Wait for the transfer request to complete before reading the state.
      # The page is already on edit_project_path before the form is submitted,
      # so have_current_path alone does not wait for the redirect.
      expect(page).to have_content(transfer_scheduled_message)
      expect(project.project_namespace.reload.state).to eq('transfer_scheduled')
    end
  end

  context 'when the target namespace already holds a project with the same name' do
    before do
      create(:project, namespace: group, name: project.name, path: project.path)
    end

    it 'reports the conflict instead of reporting the transfer as scheduled' do
      transfer_project(project, group)

      expect(page).to have_content('Project with same name or path in target namespace already exists')
      expect(page).to have_no_content('scheduled for transfer')
      expect(project.reload.namespace).to eq(user.namespace)
    end
  end
end
