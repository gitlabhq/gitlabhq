require 'spec_helper'

describe 'Project settings > [EE] Merge Requests', feature: true, js: true do
  include GitlabRoutingHelper
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, approvals_before_merge: 1) }
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

    find('#s2id_approver_user_and_group_ids .select2-input').click

    wait_for_ajax

    expect(find('.select2-results')).to have_content(group.name)

    find('.select2-results .group-result').click

    click_button 'Save changes'

    expect(page).to have_css('.js-current-approvers li.approver-group', count: 1)
  end

  context 'with an approver group' do
    before do
      create(:approver_group, group: group, target: project)
    end

    scenario 'removes approver group' do
      visit edit_project_path(project)

      expect(find('.js-current-approvers')).to have_content(group.name)

      within('.js-current-approvers') do
        click_on "Remove"
      end

      expect(find('.js-current-approvers')).not_to have_content(group.name)
    end
  end
end
