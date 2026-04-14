# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown author', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_maintainer(user)
    create(:callout, user: user, feature_name: :work_items_onboarding_modal)
    sign_in(user)

    visit project_work_items_path(project)
  end

  describe 'behavior' do
    it 'loads all the authors when opened' do
      select_tokens 'Author', '='

      expect_suggestion_count 2
    end

    it 'shows current user at top of dropdown' do
      select_tokens 'Author', '='

      expect(page).to have_css('.gl-filtered-search-suggestion:nth-child(2)', text: user.name)
    end
  end

  describe 'selecting from dropdown without Ajax call' do
    before do
      Gitlab::Testing::RequestBlockerMiddleware.block_requests!
      select_tokens 'Author', '='
    end

    after do
      Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
    end

    it 'selects current user' do
      click_on user.username

      expect_author_token(user.username)
      expect_empty_search_term
    end
  end
end
