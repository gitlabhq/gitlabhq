# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > Real-time sidebar', :js, :with_license, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:label)  { create(:label, project: project, name: 'Development') }

  let(:labels_widget) { find_by_testid('sidebar-labels') }
  let(:labels_value) { find_by_testid('value-wrapper') }

  it 'updates the assignee in real-time' do
    using_session :other_session do
      visit project_issue_path(project, issue)
      expect(page.find('.assignee')).to have_content 'None'
    end

    sign_in(user)

    visit project_issue_path(project, issue)
    expect(page.find('.assignee')).to have_content 'None'

    click_button 'assign yourself'
    wait_for_requests
    expect(page.find('.assignee')).to have_content user.name

    using_session :other_session do
      expect(page.find('.assignee')).to have_content user.name
    end
  end

  it 'updates the label in real-time' do
    using_session :other_session do
      visit project_issue_path(project, issue)
      wait_for_requests
      expect(labels_value).to have_content('None')
    end

    sign_in(user)

    visit project_issue_path(project, issue)
    wait_for_requests
    expect(labels_value).to have_content('None')

    page.within(labels_widget) do
      click_on 'Edit'
    end

    wait_for_all_requests

    page.within(labels_widget) do
      click_button label.name
      click_button 'Close'
    end

    wait_for_requests

    expect(labels_value).to have_content(label.name)

    using_session :other_session do
      expect(labels_value).to have_content(label.name)
    end
  end
end
