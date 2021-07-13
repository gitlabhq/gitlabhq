# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown emoji', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user, name: 'administrator', username: 'root') }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: issue) }

  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_emoji) { '#js-dropdown-my-reaction' }
  let(:filter_dropdown) { find("#{js_dropdown_emoji} .filter-dropdown") }

  before do
    project.add_maintainer(user)
    create_list(:award_emoji, 2, user: user, name: 'thumbsup')
    create_list(:award_emoji, 1, user: user, name: 'thumbsdown')
    create_list(:award_emoji, 3, user: user, name: 'star')
  end

  context 'when user not logged in' do
    before do
      visit project_issues_path(project)
    end

    describe 'behavior' do
      it 'does not open when the search bar has my-reaction=' do
        filtered_search.set('my-reaction=')

        expect(page).not_to have_css(js_dropdown_emoji)
      end
    end
  end

  context 'when user loggged in' do
    before do
      sign_in(user)

      visit project_issues_path(project)
    end

    describe 'behavior' do
      it 'opens when the search bar has my-reaction=' do
        filtered_search.set('my-reaction:=')

        expect(page).to have_css(js_dropdown_emoji, visible: true)
      end

      it 'loads all the emojis when opened' do
        input_filtered_search('my-reaction:=', submit: false, extra_space: false)

        expect_filtered_search_dropdown_results(filter_dropdown, 3)
      end

      it 'shows the most populated emoji at top of dropdown' do
        input_filtered_search('my-reaction:=', submit: false, extra_space: false)

        expect(first("#{js_dropdown_emoji} .filter-dropdown li")).to have_content(award_emoji_star.name)
      end
    end
  end
end
