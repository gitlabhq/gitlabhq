require 'spec_helper'

describe 'Project settings > [EE] Merge Requests', feature: true, js: true do
  include GitlabRoutingHelper

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, approvals_before_merge: 1) }
  let(:group) { create(:group) }
  let(:group_member) { create(:user) }
  let(:non_member) { create(:user) }

  before do
    sign_in(user)
    project.team << [user, :master]
    group.add_developer(user)
    group.add_developer(group_member)
  end

  scenario 'adds approver' do
    visit edit_project_path(project)

    find('#s2id_approver_user_and_group_ids .select2-input').click

    wait_for_requests

    expect(find('.select2-results')).to have_content(user.name)
    find('.user-result', text: user.name).click
    click_button 'Add'

    expect(find('.js-current-approvers')).to have_content(user.name)

    find('.js-select-user-and-group').click

    expect(find('.select2-results')).not_to have_content(user.name)
  end

  scenario 'filter approvers' do
    visit edit_project_path(project)
    find('.js-select-user-and-group').click

    expect(find('.select2-results')).to have_content(user.name)
    expect(find('.select2-results')).not_to have_content(non_member.name)
  end

  scenario 'adds approver group' do
    visit edit_project_path(project)

    find('#s2id_approver_user_and_group_ids .select2-input').click

    wait_for_requests

    within('.js-current-approvers') do
      expect(find('.panel-heading .badge')).to have_content('0')
    end

    expect(find('.select2-results')).to have_content(group.name)
    find('.select2-results .group-result').click
    click_button 'Add'

    expect(find('.approver-list-loader')).to be_visible
    expect(page).to have_css('.js-current-approvers li.approver-group', count: 1)

    expect(page).to have_css('.js-current-approvers li.approver-group', count: 1)
    within('.js-current-approvers') do
      expect(find('.panel-heading .badge')).to have_content('2')
    end
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

  context 'issuable default templates feature not available' do
    before do
      stub_licensed_features(issuable_default_templates: false)
    end

    scenario 'input to configure merge request template is not shown' do
      visit edit_project_path(project)

      expect(page).not_to have_selector('#project_merge_requests_template')
    end
  end

  context 'issuable default templates feature is available' do
    before do
      stub_licensed_features(issuable_default_templates: true)
    end

    scenario 'input to configure merge request template is not shown' do
      visit edit_project_path(project)

      expect(page).to have_selector('#project_merge_requests_template')
    end
  end
end
