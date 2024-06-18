# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Visual tokens', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, name: 'administrator', username: 'root') }
  let_it_be(:user_rock) { create(:user, name: 'The Rock', username: 'rock') }
  let_it_be(:milestone_nine) { create(:milestone, title: '9.0', project: project) }
  let_it_be(:milestone_ten) { create(:milestone, title: '10.0', project: project) }
  let_it_be(:label) { create(:label, project: project, title: 'abc') }
  let_it_be(:cc_label) { create(:label, project: project, title: 'Community Contribution') }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_member(user, :maintainer)
    project.add_member(user_rock, :maintainer)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'editing a single token' do
    before do
      select_tokens 'Author', '=', user.username, 'Assignee', '=', 'None'
      click_token_segment(user.name)
    end

    it 'opens author dropdown' do
      expect_visible_suggestions_list
      expect(page).to have_field('Search', with: 'root')
    end

    it 'filters value' do
      send_keys :backspace

      expect_suggestion_count 1
    end

    it 'ends editing mode when document is clicked' do
      find('body').click(x: 0, y: 0)

      expect_empty_search_term
      expect_hidden_suggestions_list
    end

    describe 'selecting different author from dropdown' do
      before do
        send_keys :backspace, :backspace, :backspace, :backspace
        click_on user_rock.name
      end

      it 'changes value in visual token' do
        expect_author_token(user_rock.name)
      end
    end
  end

  describe 'editing multiple tokens' do
    before do
      select_tokens 'Author', '=', user.username, 'Assignee', '=', 'None'
      click_token_segment(user.name)
    end

    it 'opens author dropdown' do
      expect_visible_suggestions_list
    end

    it 'opens assignee dropdown' do
      click_token_segment 'Assignee'

      expect_visible_suggestions_list
    end
  end

  describe 'editing a search term while editing another filter token' do
    before do
      click_filtered_search_bar
      send_keys 'foo', :enter
      select_tokens 'Assignee', '='
      click_token_segment 'foo'
      send_keys :enter
    end

    it 'opens author dropdown' do
      click_on 'Author'

      expect_suggestion '='
      expect_suggestion '!='

      click_on 'is ='

      expect_suggestion(user.name)
      expect_suggestion(user_rock.name)
    end
  end

  describe 'search using incomplete visual tokens' do
    before do
      select_tokens 'Author', '=', user.username, 'Assignee', '=', 'None'
    end

    it 'tokenizes the search term to complete visual token' do
      expect_author_token(user.name)
      expect_assignee_token 'None'
    end
  end

  it 'does retain hint token when mix of typing and clicks are performed' do
    select_tokens 'Label'
    click_on 'is ='

    expect_token_segment 'Label'
    expect_token_segment 'is'
  end

  describe 'Any/None option' do
    it 'hidden when NOT operator is selected' do
      select_tokens 'Milestone', '!='

      expect_no_suggestion 'Any'
      expect_no_suggestion 'None'
    end

    it 'shown when EQUAL operator is selected' do
      select_tokens 'Milestone', '='

      expect_suggestion 'Any'
      expect_suggestion 'None'
    end
  end
end
