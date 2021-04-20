# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Boards' do
  let(:group) { create(:group) }
  let!(:project) { create(:project_empty_repo, group: group) }
  let(:user) { create(:group_member, :maintainer, user: create(:user), group: group ).user }

  before do
    sign_in(user)
  end

  context 'Creates a an issue', :js do
    before do
      visit group_boards_path(group)
    end

    it 'adds an issue to the backlog' do
      page.within(find('.board', match: :first)) do
        issue_title = 'New Issue'
        find(:css, '.issue-count-badge-add-button').click

        wait_for_requests

        expect(find('.board-new-issue-form')).to be_visible

        fill_in 'issue_title', with: issue_title

        page.within("[data-testid='project-select-dropdown']") do
          find('button.gl-dropdown-toggle').click

          find('.gl-new-dropdown-item button').click
        end

        click_button 'Create issue'

        expect(page).to have_content(issue_title)
      end
    end
  end
end
