# frozen_string_literal: true

require 'rails_helper'

describe 'Group Boards' do
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

    it 'Adds an issue to the backlog' do
      page.within(find('.board', match: :first)) do
        issue_title = 'New Issue'
        find(:css, '.issue-count-badge-add-button').click
        expect(find('.board-new-issue-form')).to be_visible

        fill_in 'issue_title', with: issue_title
        find('.dropdown-menu-toggle').click

        wait_for_requests

        click_link(project.name)
        click_button 'Submit issue'

        expect(page).to have_content(issue_title)
      end
    end
  end
end
