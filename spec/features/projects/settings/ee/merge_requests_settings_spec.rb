require 'spec_helper'

describe 'Project settings > [EE] Merge Requests', feature: true, js: true do
  include GitlabRoutingHelper
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:group) { create(:group) }
  let(:approver) { create(:user) }

  before do
    login_as(user)
    project.team << [user, :master]
    group.add_developer(approver)
    group.add_developer(user)
  end

  scenario 'adds approver group' do
    visit edit_project_path(project)

    find('#s2id_project_approver_group_ids .select2-input').click

    wait_for_ajax

    expect(find('.select2-results')).to have_content(group.name)

    find('.select2-results').click

    click_button 'Save changes'

    expect(page).to have_css('.approver-list li.approver-group', count: 1)
  end

  context 'with an approver group' do
    before do
      create(:approver_group, group: group, target: project)
    end

    scenario 'removes approver group' do
      visit edit_project_path(project)

      expect(find('.approver-list')).to have_content(group.name)

      within('.approver-list') do
        click_on "Remove"
      end

      expect(find('.approver-list')).not_to have_content(group.name)
    end
  end
end
