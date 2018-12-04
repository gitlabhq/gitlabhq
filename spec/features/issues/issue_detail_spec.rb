require 'rails_helper'

describe 'Issue Detail', :js do
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

  context 'when issue description has xss snippet' do
    before do
      issue.update!(description: '![xss" onload=alert(1);//](a)')
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_requests
    end

    it 'should encode the description to prevent xss issues' do
      page.within('.issuable-details .detail-page-description') do
        expect(page).to have_selector('img', count: 1)
        expect(find('img')['onerror']).to be_nil
        expect(find('img')['src']).to end_with('/a')
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
