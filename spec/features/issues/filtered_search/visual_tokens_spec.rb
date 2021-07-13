# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Visual tokens', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, name: 'administrator', username: 'root') }
  let_it_be(:user_rock) { create(:user, name: 'The Rock', username: 'rock') }
  let_it_be(:milestone_nine) { create(:milestone, title: '9.0', project: project) }
  let_it_be(:milestone_ten) { create(:milestone, title: '10.0', project: project) }
  let_it_be(:label) { create(:label, project: project, title: 'abc') }
  let_it_be(:cc_label) { create(:label, project: project, title: 'Community Contribution') }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_author_dropdown) { find("#js-dropdown-author .filter-dropdown") }
  let(:filter_assignee_dropdown) { find("#js-dropdown-assignee .filter-dropdown") }
  let(:filter_milestone_dropdown) { find("#js-dropdown-milestone .filter-dropdown") }
  let(:filter_label_dropdown) { find("#js-dropdown-label .filter-dropdown") }

  def is_input_focused
    page.evaluate_script("document.activeElement.classList.contains('filtered-search')")
  end

  before do
    project.add_user(user, :maintainer)
    project.add_user(user_rock, :maintainer)
    sign_in(user)

    set_cookie('sidebar_collapsed', 'true')

    visit project_issues_path(project)
  end

  describe 'editing a single token' do
    before do
      input_filtered_search('author:=@root assignee:=none', submit: false)
      first('.tokens-container .filtered-search-token').click
      wait_for_requests
    end

    it 'opens author dropdown' do
      expect(page).to have_css('#js-dropdown-author', visible: true)
      expect_filtered_search_input('@root')
    end

    it 'filters value' do
      filtered_search.send_keys(:backspace)

      expect(page).to have_css('#js-dropdown-author .filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'ends editing mode when document is clicked' do
      find('.js-navbar').click

      expect_filtered_search_input_empty
      expect(page).to have_css('#js-dropdown-author', visible: false)
    end

    describe 'selecting different author from dropdown' do
      before do
        filter_author_dropdown.find('.filter-dropdown-item .dropdown-light-content', text: "@#{user_rock.username}").click
      end

      it 'changes value in visual token' do
        wait_for_requests
        expect(first('.tokens-container .filtered-search-token .value').text).to eq("#{user_rock.name}")
      end

      it 'moves input to the right' do
        expect(is_input_focused).to eq(true)
      end
    end
  end

  describe 'editing multiple tokens' do
    before do
      input_filtered_search('author:=@root assignee:=none', submit: false)
      first('.tokens-container .filtered-search-token').click
    end

    it 'opens author dropdown' do
      expect(page).to have_css('#js-dropdown-author', visible: true)
    end

    it 'opens assignee dropdown' do
      find('.tokens-container .filtered-search-token', text: 'Assignee').click
      expect(page).to have_css('#js-dropdown-assignee', visible: true)
    end
  end

  describe 'editing a search term while editing another filter token' do
    before do
      input_filtered_search('foo assignee:=', submit: false)
      first('.tokens-container .filtered-search-term').click
    end

    it 'opens author dropdown' do
      find('#js-dropdown-hint .filter-dropdown .filter-dropdown-item', text: 'Author').click

      expect(page).to have_css('#js-dropdown-operator', visible: true)
      expect(page).to have_css('#js-dropdown-author', visible: false)

      find('#js-dropdown-operator .filter-dropdown .filter-dropdown-item[data-value="="]').click

      expect(page).to have_css('#js-dropdown-operator', visible: false)
      expect(page).to have_css('#js-dropdown-author', visible: true)
    end
  end

  describe 'add new token after editing existing token' do
    before do
      input_filtered_search('author:=@root assignee:=none', submit: false)
      first('.tokens-container .filtered-search-token').click
      filtered_search.send_keys(' ')
    end

    describe 'opens dropdowns' do
      it 'opens hint dropdown' do
        expect(page).to have_css('#js-dropdown-hint', visible: true)
      end

      it 'opens token dropdown' do
        filtered_search.send_keys('author:=')

        expect(page).to have_css('#js-dropdown-author', visible: true)
      end
    end

    describe 'visual tokens' do
      it 'creates visual token' do
        filtered_search.send_keys('author:=@thomas ')
        token = page.all('.tokens-container .filtered-search-token')[1]

        expect(token.find('.name').text).to eq('Author')
        expect(token.find('.value').text).to eq('@thomas')
      end
    end

    it 'does not tokenize incomplete token' do
      filtered_search.send_keys('author:=')

      find('.js-navbar').click
      token = page.all('.tokens-container .js-visual-token')[1]

      expect_filtered_search_input_empty
      expect(token.find('.name').text).to eq('Author')
    end
  end

  describe 'search using incomplete visual tokens' do
    before do
      input_filtered_search('author:=@root assignee:=none', extra_space: false)
    end

    it 'tokenizes the search term to complete visual token' do
      expect_tokens([
        author_token(user.name),
        assignee_token('None')
      ])
    end
  end

  it 'does retain hint token when mix of typing and clicks are performed' do
    input_filtered_search('label:', extra_space: false, submit: false)

    expect(page).to have_css('#js-dropdown-operator', visible: true)

    find('#js-dropdown-operator li[data-value="="]').click

    token = page.all('.tokens-container .js-visual-token')[0]

    expect(token.find('.name').text).to eq('Label')
    expect(token.find('.operator').text).to eq('=')
  end

  describe 'Any/None option' do
    it 'hidden when NOT operator is selected' do
      input_filtered_search('milestone:!=', extra_space: false, submit: false)

      expect(page).not_to have_selector("#js-dropdown-milestone", text: 'Any')
      expect(page).not_to have_selector("#js-dropdown-milestone", text: 'None')
    end

    it 'shown when EQUAL operator is selected' do
      input_filtered_search('milestone:=', extra_space: false, submit: false)

      expect(page).to have_selector("#js-dropdown-milestone", text: 'Any')
      expect(page).to have_selector("#js-dropdown-milestone", text: 'None')
    end
  end
end
