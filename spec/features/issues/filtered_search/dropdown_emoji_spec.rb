require 'rails_helper'

describe 'Dropdown emoji', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project, :public) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let!(:issue) { create(:issue, project: project) }
  let!(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: issue) }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_emoji) { '#js-dropdown-my-reaction' }

  def send_keys_to_filtered_search(input)
    input.split("").each do |i|
      filtered_search.send_keys(i)
    end

    sleep 0.5
    wait_for_requests
  end

  def dropdown_emoji_size
    page.all('#js-dropdown-my-reaction .filter-dropdown .filter-dropdown-item').size
  end

  def click_emoji(text)
    find('#js-dropdown-my-reaction .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.add_master(user)
    create_list(:award_emoji, 2, user: user, name: 'thumbsup')
    create_list(:award_emoji, 1, user: user, name: 'thumbsdown')
    create_list(:award_emoji, 3, user: user, name: 'star')
    create_list(:award_emoji, 1, user: user, name: 'tea')
  end

  context 'when user not logged in' do
    before do
      visit project_issues_path(project)
    end

    describe 'behavior' do
      it 'does not open when the search bar has my-reaction:' do
        filtered_search.set('my-reaction:')

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
      it 'opens when the search bar has my-reaction:' do
        filtered_search.set('my-reaction:')

        expect(page).to have_css(js_dropdown_emoji, visible: true)
      end

      it 'closes when the search bar is unfocused' do
        find('body').click()

        expect(page).to have_css(js_dropdown_emoji, visible: false)
      end

      it 'should show loading indicator when opened' do
        slow_requests do
          filtered_search.set('my-reaction:')

          expect(page).to have_css('#js-dropdown-my-reaction .filter-dropdown-loading', visible: true)
        end
      end

      it 'should hide loading indicator when loaded' do
        send_keys_to_filtered_search('my-reaction:')

        expect(page).not_to have_css('#js-dropdown-my-reaction .filter-dropdown-loading')
      end

      it 'should load all the emojis when opened' do
        send_keys_to_filtered_search('my-reaction:')

        expect(dropdown_emoji_size).to eq(4)
      end

      it 'shows the most populated emoji at top of dropdown' do
        send_keys_to_filtered_search('my-reaction:')

        expect(first('#js-dropdown-my-reaction li')).to have_content(award_emoji_star.name)
      end
    end

    describe 'filtering' do
      before do
        filtered_search.set('my-reaction')
        send_keys_to_filtered_search(':')
      end

      it 'filters by name' do
        send_keys_to_filtered_search('up')

        expect(dropdown_emoji_size).to eq(1)
      end

      it 'filters by case insensitive name' do
        send_keys_to_filtered_search('Up')

        expect(dropdown_emoji_size).to eq(1)
      end
    end

    describe 'selecting from dropdown' do
      before do
        filtered_search.set('my-reaction')
        send_keys_to_filtered_search(':')
      end

      it 'fills in the my-reaction name' do
        click_emoji('thumbsup')

        wait_for_requests

        expect(page).to have_css(js_dropdown_emoji, visible: false)
        expect_tokens([emoji_token('thumbsup')])
        expect_filtered_search_input_empty
      end
    end

    describe 'input has existing content' do
      it 'opens my-reaction dropdown with existing search term' do
        filtered_search.set('searchTerm my-reaction:')

        expect(page).to have_css(js_dropdown_emoji, visible: true)
      end

      it 'opens my-reaction dropdown with existing assignee' do
        filtered_search.set('assignee:@user my-reaction:')

        expect(page).to have_css(js_dropdown_emoji, visible: true)
      end

      it 'opens my-reaction dropdown with existing label' do
        filtered_search.set('label:~bug my-reaction:')

        expect(page).to have_css(js_dropdown_emoji, visible: true)
      end

      it 'opens my-reaction dropdown with existing milestone' do
        filtered_search.set('milestone:%v1.0 my-reaction:')

        expect(page).to have_css(js_dropdown_emoji, visible: true)
      end

      it 'opens my-reaction dropdown with existing my-reaction' do
        filtered_search.set('my-reaction:star my-reaction:')

        expect(page).to have_css(js_dropdown_emoji, visible: true)
      end
    end

    describe 'caching requests' do
      it 'caches requests after the first load' do
        filtered_search.set('my-reaction')
        send_keys_to_filtered_search(':')
        initial_size = dropdown_emoji_size

        expect(initial_size).to be > 0

        create_list(:award_emoji, 1, user: user, name: 'smile')
        find('.filtered-search-box .clear-search').click
        filtered_search.set('my-reaction')
        send_keys_to_filtered_search(':')

        expect(dropdown_emoji_size).to eq(initial_size)
      end
    end
  end
end
