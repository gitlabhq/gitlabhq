# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > Real-time sidebar', :js, :with_license, feature_category: :team_planning do
  include ListboxHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:label)  { create(:label, project: project, name: 'Development') }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    sign_in(user)
  end

  it 'updates the assignee in real-time' do
    using_session :other_session do
      visit project_issue_path(project, issue)

      within_testid('work-item-assignees') do
        expect(page).to have_text('None')
      end
    end

    sign_in(user)
    visit project_issue_path(project, issue)

    click_button 'assign yourself'

    using_session :other_session do
      within_testid('work-item-assignees') do
        expect(page).to have_link user.name
      end
    end
  end

  it 'updates the label in real-time' do
    using_session :other_session do
      visit project_issue_path(project, issue)

      within_testid('work-item-labels') do
        expect(page).to have_text('None')
      end
    end

    sign_in(user)
    visit project_issue_path(project, issue)

    within_testid('work-item-labels') do
      click_on 'Edit'
      select_listbox_item(label.name)
      send_keys :escape
    end

    using_session :other_session do
      within_testid('work-item-labels') do
        expect(page).to have_link(label.name)
      end
    end
  end
end
