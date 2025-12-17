# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issue move to another project', :js, feature_category: :team_planning do
  include ListboxHelpers

  let(:user) { create(:user) }
  let(:old_project) { create(:project, :repository) }
  let(:text) { 'Some issue description' }

  let(:issue) do
    create(:issue, description: text, project: old_project, author: user)
  end

  before do
    sign_in(user)
  end

  context 'user does not have permission to move issue' do
    before do
      old_project.add_guest(user)

      visit issue_path(issue)
    end

    it 'moving issue to another project not allowed' do
      click_button 'More actions', match: :first

      expect(page).not_to have_button 'Move'
    end
  end

  context 'user has permission to move issue' do
    let!(:mr) { create(:merge_request, source_project: old_project) }
    let(:new_project) { create(:project) }
    let(:new_project_search) { create(:project) }
    let(:text) { "Text with #{mr.to_reference}" }
    let(:cross_reference) { old_project.to_reference_base(new_project) }

    before do
      old_project.add_reporter(user)
      new_project.add_reporter(user)

      visit issue_path(issue)
    end

    it 'moving issue to another project' do
      click_button 'More actions', match: :first
      click_button 'Move'
      click_button 'Select project'
      send_keys :down, :enter
      click_button 'Move'

      expect(page).to have_content("Text with #{cross_reference}#{mr.to_reference}")
      expect(page).to have_content("moved from #{cross_reference}#{issue.to_reference}")
      expect(page).to have_content(issue.title)
      expect(page).to have_current_path(%r{#{project_path(new_project)}})
    end

    it 'searching project dropdown' do
      new_project_search.add_reporter(user)

      click_button 'More actions', match: :first
      click_button 'Move'
      click_button 'Select project'

      expect_listbox_item(new_project.name)

      send_keys new_project_search.name

      expect_listbox_item(new_project_search.name)
      expect_no_listbox_item(new_project.name)
    end

    context 'issue has been already moved' do
      let(:new_issue) { create(:issue, project: new_project) }
      let(:issue) do
        create(:issue, project: old_project, author: user, moved_to: new_issue)
      end

      it 'there is no option to move the already-moved issue' do
        click_button 'More actions', match: :first

        expect(page).not_to have_button('Move')
      end
    end
  end

  context 'service desk issue moved to a project with service desk disabled', :saas do
    let(:project_title) { 'service desk disabled project' }
    let(:warning_selector) { '.js-alert-moved-from-service-desk-warning' }
    let(:namespace) { create(:namespace) }
    let(:regular_project) { create(:project, title: project_title, service_desk_enabled: false) }
    let(:service_desk_project) { build(:project, :private, namespace: namespace, service_desk_enabled: true) }
    let(:support_bot) { Users::Internal.for_organization(service_desk_project.organization_id).support_bot }
    let(:service_desk_issue) { create(:issue, project: service_desk_project, author: support_bot) }

    before do
      allow(Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(true)
      allow(Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?).and_return(true)

      regular_project.add_reporter(user)
      service_desk_project.add_reporter(user)

      visit issue_path(service_desk_issue)

      click_button _('Move issue')
      wait_for_requests
      find('.gl-new-dropdown-item', text: project_title).click
      click_button _('Move')
    end

    it 'shows an alert after being moved' do
      expect(page).to have_content('This project does not have Service Desk enabled')
    end

    it 'does not show an alert after being dismissed' do
      find("#{warning_selector} .js-close").click

      expect(page).to have_no_selector(warning_selector)

      page.refresh

      expect(page).to have_no_selector(warning_selector)
    end
  end

  def issue_path(issue)
    project_issue_path(issue.project, issue)
  end
end
