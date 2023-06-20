# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User sees README', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }

  it 'shows the project README', :js do
    visit project_path(project)
    wait_for_requests

    page.within('.readme-holder') do
      expect(page).to have_content 'testme'
    end
  end

  context 'obeying robots.txt' do
    before do
      Gitlab::Testing::RobotsBlockerMiddleware.block_requests!
    end

    after do
      Gitlab::Testing::RobotsBlockerMiddleware.allow_requests!
    end

    # For example, see this regression we had in
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39520
    it 'does not block the requests necessary to load the project README', :js do
      visit project_path(project)
      wait_for_requests

      page.within('.readme-holder') do
        expect(page).to have_content 'testme'
      end
    end
  end
end
