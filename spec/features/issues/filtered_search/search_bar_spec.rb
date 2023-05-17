# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Search bar', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'keyboard navigation' do
    it 'selects item' do
      click_filtered_search_bar
      send_keys :down, :enter

      expect_token_segment 'Assignee'
    end
  end

  describe 'clear search button' do
    it 'clears text' do
      search_text = 'search_text'
      click_filtered_search_bar
      send_keys search_text

      expect(page).to have_field 'Search', with: search_text

      click_button 'Clear'

      expect(page).to have_field 'Search', with: ''
    end

    it 'hides by default' do
      expect(page).not_to have_button 'Clear'
    end

    it 'hides after clicked' do
      click_filtered_search_bar
      send_keys 'a'

      click_button 'Clear'

      expect(page).not_to have_button 'Clear'
    end

    it 'hides when there is no text' do
      click_filtered_search_bar
      send_keys 'a', :backspace, :backspace

      expect(page).not_to have_button 'Clear'
    end

    it 'shows when there is text' do
      click_filtered_search_bar
      send_keys 'a'

      expect(page).to have_button 'Clear'
    end

    it 'resets the dropdown hint filter' do
      click_filtered_search_bar
      original_size = get_suggestion_count
      send_keys 'autho'

      # Expect Author, Search for this text
      expect_suggestion_count 2

      click_button 'Clear'
      click_filtered_search_bar

      expect_suggestion_count(original_size)
    end
  end
end
