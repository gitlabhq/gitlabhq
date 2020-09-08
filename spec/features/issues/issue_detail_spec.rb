# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Detail', :js do
  let(:user)     { create(:user) }
  let(:project)  { create(:project, :public) }
  let(:issue)    { create(:issue, project: project, author: user) }

  context 'when user displays the issue' do
    before do
      visit project_issue_path(project, issue)
      wait_for_requests
    end

    it 'shows the issue' do
      page.within('.issuable-details') do
        expect(find('h2')).to have_content(issue.title)
      end
    end
  end

  context 'when user displays the issue as an incident' do
    let(:issue) { create(:incident, project: project, author: user) }

    before do
      visit project_issue_path(project, issue)
      wait_for_requests
    end

    it 'does not show design management' do
      expect(page).not_to have_selector('.js-design-management')
    end
  end

  context 'when issue description has xss snippet' do
    before do
      issue.update!(description: '![xss" onload=alert(1);//](a)')

      sign_in(user)
      visit project_issue_path(project, issue)
    end

    it 'encodes the description to prevent xss issues', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/207951' do
      page.within('.issuable-details .detail-page-description') do
        image = find('img.js-lazy-loaded')

        expect(page).to have_selector('img', count: 1)
        expect(image['onerror']).to be_nil
        expect(image['src']).to end_with('/a')
      end
    end
  end

  context 'when edited by a user who is later deleted' do
    before do
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_requests

      page.find('.js-issuable-edit').click
      fill_in 'issuable-title', with: 'issue title'
      click_button 'Save'
      wait_for_requests

      Users::DestroyService.new(user).execute(user)

      visit project_issue_path(project, issue)
    end

    it 'shows the issue' do
      page.within('.issuable-details') do
        expect(find('h2')).to have_content(issue.reload.title)
      end
    end
  end
end
