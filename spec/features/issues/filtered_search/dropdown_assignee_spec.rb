# frozen_string_literal: true

require 'spec_helper'

describe 'Dropdown assignee', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let(:js_dropdown_assignee) { '#js-dropdown-assignee' }
  let(:filter_dropdown) { find("#{js_dropdown_assignee} .filter-dropdown") }

  before do
    project.add_maintainer(user)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the assignees when opened' do
      input_filtered_search('assignee=', submit: false, extra_space: false)

      expect_filtered_search_dropdown_results(filter_dropdown, 2)
    end

    it 'shows current user at top of dropdown' do
      input_filtered_search('assignee=', submit: false, extra_space: false)

      expect(filter_dropdown.first('.filter-dropdown-item')).to have_content(user.name)
    end
  end

  describe 'selecting from dropdown without Ajax call' do
    before do
      Gitlab::Testing::RequestBlockerMiddleware.block_requests!
      input_filtered_search('assignee=', submit: false, extra_space: false)
    end

    after do
      Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
    end

    it 'selects current user' do
      find("#{js_dropdown_assignee} .filter-dropdown-item", text: user.username).click

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([assignee_token(user.username)])
      expect_filtered_search_input_empty
    end
  end
end
