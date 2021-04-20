# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > Real-time sidebar', :js do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_developer(user)
  end

  it 'updates the assignee in real-time' do
    Capybara::Session.new(:other_session)

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
end
