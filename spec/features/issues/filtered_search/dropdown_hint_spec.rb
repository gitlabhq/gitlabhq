require 'rails_helper'

describe 'Dropdown hint', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project, :public) }
  let!(:user) { create(:user) }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_hint) { '#js-dropdown-hint' }

  def click_hint(text)
    find('#js-dropdown-hint .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.add_master(user)
    create(:issue, project: project)
  end

  context 'when user not logged in' do
    before do
      visit project_issues_path(project)
    end

    it 'does not exist my-reaction dropdown item' do
      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).not_to have_content('my-reaction')
    end
  end

  context 'when user logged in' do
    before do
      sign_in(user)

      visit project_issues_path(project)
    end

    describe 'behavior' do
      before do
        expect(page).to have_css(js_dropdown_hint, visible: false)
        filtered_search.click
      end

      it 'opens when the search bar is first focused' do
        expect(page).to have_css(js_dropdown_hint, visible: true)
      end

      it 'closes when the search bar is unfocused' do
        find('body').click

        expect(page).to have_css(js_dropdown_hint, visible: false)
      end
    end

    describe 'filtering' do
      it 'does not filter `Press Enter or click to search`' do
        filtered_search.set('randomtext')

        hint_dropdown = find(js_dropdown_hint)

        expect(hint_dropdown).to have_content('Press Enter or click to search')
        expect(hint_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 0)
      end

      it 'filters with text' do
        filtered_search.set('a')

        expect(find(js_dropdown_hint)).to have_selector('.filter-dropdown .filter-dropdown-item', count: 4)
      end
    end

    describe 'selecting from dropdown with no input' do
      before do
        filtered_search.click
      end

      it 'opens the author dropdown when you click on author' do
        click_hint('author')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-author', visible: true)
        expect_tokens([{ name: 'author' }])
        expect_filtered_search_input_empty
      end

      it 'opens the assignee dropdown when you click on assignee' do
        click_hint('assignee')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-assignee', visible: true)
        expect_tokens([{ name: 'assignee' }])
        expect_filtered_search_input_empty
      end

      it 'opens the milestone dropdown when you click on milestone' do
        click_hint('milestone')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-milestone', visible: true)
        expect_tokens([{ name: 'milestone' }])
        expect_filtered_search_input_empty
      end

      it 'opens the label dropdown when you click on label' do
        click_hint('label')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-label', visible: true)
        expect_tokens([{ name: 'label' }])
        expect_filtered_search_input_empty
      end

      it 'opens the emoji dropdown when you click on my-reaction' do
        click_hint('my-reaction')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-my-reaction', visible: true)
        expect_tokens([{ name: 'my-reaction' }])
        expect_filtered_search_input_empty
      end
    end

    describe 'selecting from dropdown with some input' do
      it 'opens the author dropdown when you click on author' do
        filtered_search.set('auth')
        click_hint('author')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-author', visible: true)
        expect_tokens([{ name: 'author' }])
        expect_filtered_search_input_empty
      end

      it 'opens the assignee dropdown when you click on assignee' do
        filtered_search.set('assign')
        click_hint('assignee')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-assignee', visible: true)
        expect_tokens([{ name: 'assignee' }])
        expect_filtered_search_input_empty
      end

      it 'opens the milestone dropdown when you click on milestone' do
        filtered_search.set('mile')
        click_hint('milestone')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-milestone', visible: true)
        expect_tokens([{ name: 'milestone' }])
        expect_filtered_search_input_empty
      end

      it 'opens the label dropdown when you click on label' do
        filtered_search.set('lab')
        click_hint('label')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-label', visible: true)
        expect_tokens([{ name: 'label' }])
        expect_filtered_search_input_empty
      end

      it 'opens the emoji dropdown when you click on my-reaction' do
        filtered_search.set('my')
        click_hint('my-reaction')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-my-reaction', visible: true)
        expect_tokens([{ name: 'my-reaction' }])
        expect_filtered_search_input_empty
      end
    end

    describe 'reselecting from dropdown' do
      it 'reuses existing author text' do
        filtered_search.send_keys('author:')
        filtered_search.send_keys(:backspace)
        filtered_search.send_keys(:backspace)
        click_hint('author')

        expect_tokens([{ name: 'author' }])
        expect_filtered_search_input_empty
      end

      it 'reuses existing assignee text' do
        filtered_search.send_keys('assignee:')
        filtered_search.send_keys(:backspace)
        filtered_search.send_keys(:backspace)
        click_hint('assignee')

        expect_tokens([{ name: 'assignee' }])
        expect_filtered_search_input_empty
      end

      it 'reuses existing milestone text' do
        filtered_search.send_keys('milestone:')
        filtered_search.send_keys(:backspace)
        filtered_search.send_keys(:backspace)
        click_hint('milestone')

        expect_tokens([{ name: 'milestone' }])
        expect_filtered_search_input_empty
      end

      it 'reuses existing label text' do
        filtered_search.send_keys('label:')
        filtered_search.send_keys(:backspace)
        filtered_search.send_keys(:backspace)
        click_hint('label')

        expect_tokens([{ name: 'label' }])
        expect_filtered_search_input_empty
      end

      it 'reuses existing emoji text' do
        filtered_search.send_keys('my-reaction:')
        filtered_search.send_keys(:backspace)
        filtered_search.send_keys(:backspace)
        click_hint('my-reaction')

        expect_tokens([{ name: 'my-reaction' }])
        expect_filtered_search_input_empty
      end
    end
  end
end
