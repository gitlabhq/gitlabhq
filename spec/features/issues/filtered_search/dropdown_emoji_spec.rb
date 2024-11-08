# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown emoji', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: issue) }

  before do
    project.add_maintainer(user)
    create_list(:award_emoji, 2, user: user, name: AwardEmoji::THUMBS_UP)
    create_list(:award_emoji, 1, user: user, name: AwardEmoji::THUMBS_DOWN)
    create_list(:award_emoji, 3, user: user, name: 'star')
  end

  context 'when user not logged in' do
    before do
      visit project_issues_path(project)
    end

    describe 'behavior' do
      it 'does not contain My-Reaction in the list of suggestions' do
        click_filtered_search_bar

        expect(page).not_to have_link 'My-Reaction'
      end
    end
  end

  context 'when user logged in' do
    before do
      sign_in(user)

      visit project_issues_path(project)
    end

    describe 'behavior' do
      it 'loads all the emojis when opened' do
        select_tokens 'My-Reaction', '='

        # Expect None, Any, star, thumbsup, thumbsdown
        expect_suggestion_count 5
      end

      it 'shows the most populated emoji at top of dropdown' do
        select_tokens 'My-Reaction', '='

        # List items 1-3 are None, Any, divider
        expect(page).to have_css('.gl-filtered-search-suggestion-list li:nth-child(4)', text: award_emoji_star.name)
      end
    end
  end
end
