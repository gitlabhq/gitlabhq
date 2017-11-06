require 'rails_helper'

describe 'Visual tokens', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let!(:user_rock) { create(:user, name: 'The Rock', username: 'rock') }
  let!(:milestone_nine) { create(:milestone, title: '9.0', project: project) }
  let!(:milestone_ten) { create(:milestone, title: '10.0', project: project) }
  let!(:label) { create(:label, project: project, title: 'abc') }
  let!(:cc_label) { create(:label, project: project, title: 'Community Contribution') }

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_author_dropdown) { find("#js-dropdown-author .filter-dropdown") }
  let(:filter_assignee_dropdown) { find("#js-dropdown-assignee .filter-dropdown") }
  let(:filter_milestone_dropdown) { find("#js-dropdown-milestone .filter-dropdown") }
  let(:filter_label_dropdown) { find("#js-dropdown-label .filter-dropdown") }

  def is_input_focused
    page.evaluate_script("document.activeElement.classList.contains('filtered-search')")
  end

  before do
    project.add_user(user, :master)
    project.add_user(user_rock, :master)
    sign_in(user)
    create(:issue, project: project)

    set_cookie('sidebar_collapsed', 'true')

    visit project_issues_path(project)
  end

  describe 'editing author token' do
    before do
      input_filtered_search('author:@root assignee:none', submit: false)
      first('.tokens-container .filtered-search-token').click
    end

    it 'opens author dropdown' do
      expect(page).to have_css('#js-dropdown-author', visible: true)
    end

    it 'makes value editable' do
      expect_filtered_search_input('@root')
    end

    it 'filters value' do
      filtered_search.send_keys(:backspace)

      expect(page).to have_css('#js-dropdown-author .filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'ends editing mode when document is clicked' do
      find('#content-body').click

      expect_filtered_search_input_empty
      expect(page).to have_css('#js-dropdown-author', visible: false)
    end

    it 'ends editing mode when scroll container is clicked' do
      find('.scroll-container').click

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

  describe 'editing assignee token' do
    before do
      input_filtered_search('assignee:@root author:none', submit: false)
      first('.tokens-container .filtered-search-token').double_click
    end

    it 'opens assignee dropdown' do
      expect(page).to have_css('#js-dropdown-assignee', visible: true)
    end

    it 'makes value editable' do
      expect_filtered_search_input('@root')
    end

    it 'filters value' do
      filtered_search.send_keys(:backspace)

      expect(page).to have_css('#js-dropdown-assignee .filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'ends editing mode when document is clicked' do
      find('#content-body').click

      expect_filtered_search_input_empty
      expect(page).to have_css('#js-dropdown-assignee', visible: false)
    end

    it 'ends editing mode when scroll container is clicked' do
      find('.scroll-container').click

      expect_filtered_search_input_empty
      expect(page).to have_css('#js-dropdown-assignee', visible: false)
    end

    describe 'selecting static option from dropdown' do
      before do
        find("#js-dropdown-assignee").find('.filter-dropdown-item', text: 'No Assignee').click
      end

      it 'changes value in visual token' do
        expect(first('.tokens-container .filtered-search-token .value').text).to eq('none')
      end

      it 'moves input to the right' do
        expect(is_input_focused).to eq(true)
      end
    end
  end

  describe 'editing milestone token' do
    before do
      input_filtered_search('milestone:%10.0 author:none', submit: false)
      first('.tokens-container .filtered-search-token').click
      first('#js-dropdown-milestone .filter-dropdown .filter-dropdown-item')
    end

    it 'opens milestone dropdown' do
      expect(filter_milestone_dropdown.find('.filter-dropdown-item', text: milestone_ten.title)).to be_visible
      expect(filter_milestone_dropdown.find('.filter-dropdown-item', text: milestone_nine.title)).to be_visible
      expect(page).to have_css('#js-dropdown-milestone', visible: true)
    end

    it 'selects static option from dropdown' do
      find("#js-dropdown-milestone").find('.filter-dropdown-item', text: 'Upcoming').click

      expect(first('.tokens-container .filtered-search-token .value').text).to eq('upcoming')
      expect(is_input_focused).to eq(true)
    end

    it 'makes value editable' do
      expect_filtered_search_input('%10.0')
    end

    it 'filters value' do
      filtered_search.send_keys(:backspace)

      expect(page).to have_css('#js-dropdown-milestone .filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'ends editing mode when document is clicked' do
      find('#content-body').click

      expect_filtered_search_input_empty
      expect(page).to have_css('#js-dropdown-milestone', visible: false)
    end

    it 'ends editing mode when scroll container is clicked' do
      find('.scroll-container').click

      expect_filtered_search_input_empty
      expect(page).to have_css('#js-dropdown-milestone', visible: false)
    end
  end

  describe 'editing label token' do
    before do
      input_filtered_search("label:~#{label.title} author:none", submit: false)
      first('.tokens-container .filtered-search-token').double_click
      first('#js-dropdown-label .filter-dropdown .filter-dropdown-item')
    end

    it 'opens label dropdown' do
      expect(filter_label_dropdown.find('.filter-dropdown-item', text: label.title)).to be_visible
      expect(filter_label_dropdown.find('.filter-dropdown-item', text: cc_label.title)).to be_visible
      expect(page).to have_css('#js-dropdown-label', visible: true)
    end

    it 'selects option from dropdown' do
      expect(filter_label_dropdown.find('.filter-dropdown-item', text: label.title)).to be_visible
      expect(filter_label_dropdown.find('.filter-dropdown-item', text: cc_label.title)).to be_visible

      find("#js-dropdown-label").find('.filter-dropdown-item', text: cc_label.title).click

      expect(first('.tokens-container .filtered-search-token .value').text).to eq("~\"#{cc_label.title}\"")
      expect(is_input_focused).to eq(true)
    end

    it 'makes value editable' do
      expect_filtered_search_input("~#{label.title}")
    end

    it 'filters value' do
      expect(filter_label_dropdown.find('.filter-dropdown-item', text: label.title)).to be_visible
      expect(filter_label_dropdown.find('.filter-dropdown-item', text: cc_label.title)).to be_visible

      filtered_search.send_keys(:backspace)

      filter_label_dropdown.find('.filter-dropdown-item')

      expect(page.all('#js-dropdown-label .filter-dropdown .filter-dropdown-item').size).to eq(1)
    end

    it 'ends editing mode when document is clicked' do
      find('#content-body').click

      expect_filtered_search_input_empty
      expect(page).to have_css('#js-dropdown-label', visible: false)
    end

    it 'ends editing mode when scroll container is clicked' do
      find('.scroll-container').click

      expect_filtered_search_input_empty
      expect(page).to have_css('#js-dropdown-label', visible: false)
    end
  end

  describe 'editing multiple tokens' do
    before do
      input_filtered_search('author:@root assignee:none', submit: false)
      first('.tokens-container .filtered-search-token').double_click
    end

    it 'opens author dropdown' do
      expect(page).to have_css('#js-dropdown-author', visible: true)
    end

    it 'opens assignee dropdown' do
      find('.tokens-container .filtered-search-token', text: 'Assignee').double_click
      expect(page).to have_css('#js-dropdown-assignee', visible: true)
    end
  end

  describe 'editing a search term while editing another filter token' do
    before do
      input_filtered_search('author assignee:', submit: false)
      first('.tokens-container .filtered-search-term').double_click
    end

    it 'opens hint dropdown' do
      expect(page).to have_css('#js-dropdown-hint', visible: true)
    end

    it 'opens author dropdown' do
      find('#js-dropdown-hint .filter-dropdown .filter-dropdown-item', text: 'author').click

      expect(page).to have_css('#js-dropdown-author', visible: true)
    end
  end

  describe 'add new token after editing existing token' do
    before do
      input_filtered_search('author:@root assignee:none', submit: false)
      first('.tokens-container .filtered-search-token').double_click
      filtered_search.send_keys(' ')
    end

    describe 'opens dropdowns' do
      it 'opens hint dropdown' do
        expect(page).to have_css('#js-dropdown-hint', visible: true)
      end

      it 'opens author dropdown' do
        filtered_search.send_keys('author:')
        expect(page).to have_css('#js-dropdown-author', visible: true)
      end

      it 'opens assignee dropdown' do
        filtered_search.send_keys('assignee:')
        expect(page).to have_css('#js-dropdown-assignee', visible: true)
      end

      it 'opens milestone dropdown' do
        filtered_search.send_keys('milestone:')
        expect(page).to have_css('#js-dropdown-milestone', visible: true)
      end

      it 'opens label dropdown' do
        filtered_search.send_keys('label:')
        expect(page).to have_css('#js-dropdown-label', visible: true)
      end
    end

    describe 'creates visual tokens' do
      it 'creates author token' do
        filtered_search.send_keys('author:@thomas ')
        token = page.all('.tokens-container .filtered-search-token')[1]

        expect(token.find('.name').text).to eq('Author')
        expect(token.find('.value').text).to eq('@thomas')
      end

      it 'creates assignee token' do
        filtered_search.send_keys('assignee:@thomas ')
        token = page.all('.tokens-container .filtered-search-token')[1]

        expect(token.find('.name').text).to eq('Assignee')
        expect(token.find('.value').text).to eq('@thomas')
      end

      it 'creates milestone token' do
        filtered_search.send_keys('milestone:none ')
        token = page.all('.tokens-container .filtered-search-token')[1]

        expect(token.find('.name').text).to eq('Milestone')
        expect(token.find('.value').text).to eq('none')
      end

      it 'creates label token' do
        filtered_search.send_keys('label:~Backend ')
        token = page.all('.tokens-container .filtered-search-token')[1]

        expect(token.find('.name').text).to eq('Label')
        expect(token.find('.value').text).to eq('~Backend')
      end
    end

    it 'does not tokenize incomplete token' do
      filtered_search.send_keys('author:')

      find('body').click
      token = page.all('.tokens-container .js-visual-token')[1]

      expect_filtered_search_input_empty
      expect(token.find('.name').text).to eq('Author')
    end
  end

  describe 'search using incomplete visual tokens' do
    before do
      input_filtered_search('author:@root assignee:none', extra_space: false)
    end

    it 'tokenizes the search term to complete visual token' do
      expect_tokens([
        author_token(user.name),
        assignee_token('none')
      ])
    end
  end
end
