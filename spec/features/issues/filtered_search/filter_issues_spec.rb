# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Filter issues', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  let!(:bug_label) { create(:label, project: project, title: 'bug') }
  let!(:caps_sensitive_label) { create(:label, project: project, title: 'CaPs') }
  let!(:multiple_words_label) { create(:label, project: project, title: "Two words") }
  let!(:milestone) { create(:milestone, title: "8", project: project, start_date: 2.days.ago) }

  def expect_no_issues_list
    expect(page).to have_no_selector('.issue')
  end

  before do
    project.add_maintainer(user)

    create(:issue, project: project, author: user2, title: "Bug report 1")
    create(:issue, project: project, author: user2, title: "Bug report 2")

    create(:issue, project: project, author: user,  title: "issue by assignee", milestone: milestone, assignees: [user])
    create(:issue, project: project, author: user,  title: "issue by assignee with searchTerm", milestone: milestone, assignees: [user])

    create(:labeled_issue,
      title: "Bug 2",
      project: project,
      milestone: milestone,
      author: user,
      assignees: [user],
      labels: [bug_label])

    create(:labeled_issue,
      title: "issue by assignee with searchTerm and label",
      project: project,
      milestone: milestone,
      author: user,
      assignees: [user],
      labels: [caps_sensitive_label])

    create(:labeled_issue,
      title: "Bug report foo was possible",
      project: project,
      milestone: milestone,
      author: user,
      assignees: [user],
      labels: [bug_label, caps_sensitive_label])

    create(:labeled_issue, title: "Issue with multiple words label", project: project, labels: [multiple_words_label])

    sign_in(user)
    visit project_issues_path(project)
  end

  it 'filters by all available tokens' do
    search_term = 'issue'
    select_tokens 'Assignee', '=', user.username, 'Author', '=', user.username, 'Label', '=', caps_sensitive_label.title, 'Milestone', '=', milestone.title
    send_keys search_term, :enter, :enter

    expect_assignee_token(user.name)
    expect_author_token(user.name)
    expect_label_token(caps_sensitive_label.title)
    expect_milestone_token(milestone.title)
    expect_issues_list_count(1)
    expect_search_term(search_term)
  end

  describe 'filter issues by author' do
    context 'only author' do
      it 'filters issues by searched author' do
        select_tokens 'Author', '=', user.username, submit: true

        expect_author_token(user.name)
        expect_issues_list_count(5)
        expect_empty_search_term
      end
    end
  end

  describe 'filter issues by assignee' do
    context 'only assignee' do
      it 'filters issues by searched assignee' do
        select_tokens 'Assignee', '=', user.username, submit: true

        expect_assignee_token(user.name)
        expect_issues_list_count(5)
        expect_empty_search_term
      end

      it 'filters issues by no assignee' do
        select_tokens 'Assignee', '=', 'None', submit: true

        expect_assignee_token 'None'
        expect_issues_list_count(3)
        expect_empty_search_term
      end

      it 'filters issues by invalid assignee' do
        skip('to be tested, issue #26546')
      end
    end
  end

  describe 'filter by reviewer' do
    it 'does not allow filtering by reviewer' do
      click_filtered_search_bar

      expect(page).not_to have_button('Reviewer')
    end
  end

  describe 'filter issues by label' do
    context 'only label' do
      it 'filters issues by searched label' do
        select_tokens 'Label', '=', bug_label.title, submit: true

        expect_label_token(bug_label.title)
        expect_issues_list_count(2)
        expect_empty_search_term
      end

      it 'filters issues not containing searched label' do
        select_tokens 'Label', '!=', bug_label.title, submit: true

        expect_negated_label_token(bug_label.title)
        expect_issues_list_count(6)
        expect_empty_search_term
      end

      it 'filters issues by any label' do
        select_tokens 'Label', '=', 'Any', submit: true

        expect_label_token 'Any'
        expect_issues_list_count(4)
        expect_empty_search_term
      end

      it 'filters issues by no label' do
        select_tokens 'Label', '=', 'None', submit: true

        expect_label_token 'None'
        expect_issues_list_count(4)
        expect_empty_search_term
      end

      it 'filters issues by multiple labels' do
        select_tokens 'Label', '=', bug_label.title, 'Label', '=', caps_sensitive_label.title, submit: true

        expect_label_token(bug_label.title)
        expect_label_token(caps_sensitive_label.title)
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'filters issues by multiple labels with not operator' do
        select_tokens 'Label', '!=', bug_label.title, submit: true
        select_tokens 'Label', '=', caps_sensitive_label.title, submit: true

        expect_negated_label_token(bug_label.title)
        expect_label_token(caps_sensitive_label.title)
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'filters issues by label containing special characters' do
        special_label = create(:label, project: project, title: '!@#$%^&*()-+[]<>?/:{}|\\')
        special_issue = create(:issue, title: "Issue with special character label", project: project)
        special_issue.labels << special_label

        select_tokens 'Label', '=', special_label.title, submit: true

        expect_label_token(special_label.title)
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'filters issues by label not containing special characters' do
        special_label = create(:label, project: project, title: '!@#$%^&*()-+[]<>?/:{}|\\')
        special_issue = create(:issue, title: "Issue with special character label", project: project)
        special_issue.labels << special_label

        select_tokens 'Label', '!=', special_label.title, submit: true

        expect_negated_label_token(special_label.title)
        expect_issues_list_count(8)
        expect_empty_search_term
      end

      it 'does not show issues for unused labels' do
        new_label = create(:label, project: project, title: 'new_label')

        select_tokens 'Label', '=', new_label.title, submit: true

        expect_label_token(new_label.title)
        expect_no_issues_list
        expect_empty_search_term
      end
    end

    context 'label with multiple words' do
      it 'special characters' do
        special_multiple_label = create(:label, project: project, title: "Utmost |mp0rt@nce")
        special_multiple_issue = create(:issue, title: "Issue with special character multiple words label", project: project)
        special_multiple_issue.labels << special_multiple_label

        select_tokens 'Label', '=', special_multiple_label.title, submit: true

        # Check for search results (which makes sure that the page has changed)
        expect_issues_list_count(1)
        expect_label_token(special_multiple_label.title)
        expect_empty_search_term
      end

      it 'single quotes' do
        select_tokens 'Label', '=', multiple_words_label.title, submit: true

        expect_issues_list_count(1)
        expect_label_token(multiple_words_label.title)
        expect_empty_search_term
      end

      it 'double quotes' do
        select_tokens 'Label', '=', multiple_words_label.title, submit: true

        expect_label_token(multiple_words_label.title)
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'single quotes containing double quotes' do
        double_quotes_label = create(:label, project: project, title: 'won"t fix')
        double_quotes_label_issue = create(:issue, title: "Issue with double quotes label", project: project)
        double_quotes_label_issue.labels << double_quotes_label

        select_tokens 'Label', '=', double_quotes_label.title, submit: true

        expect_label_token(double_quotes_label.title)
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'double quotes containing single quotes' do
        single_quotes_label = create(:label, project: project, title: "won't fix")
        single_quotes_label_issue = create(:issue, title: "Issue with single quotes label", project: project)
        single_quotes_label_issue.labels << single_quotes_label

        select_tokens 'Label', '=', single_quotes_label.title, submit: true

        expect_label_token(single_quotes_label.title)
        expect_issues_list_count(1)
        expect_empty_search_term
      end
    end

    context 'multiple labels with other filters' do
      it 'filters issues by searched label, label2, author, assignee, milestone and text' do
        search_term = 'bug'
        select_tokens 'Label', '=', bug_label.title, 'Label', '=', caps_sensitive_label.title, 'Author', '=', user.username, 'Assignee', '=', user.username, 'Milestone', '=', milestone.title
        send_keys search_term, :enter, :enter

        expect_label_token(bug_label.title)
        expect_label_token(caps_sensitive_label.title)
        expect_author_token(user.name)
        expect_assignee_token(user.name)
        expect_milestone_token(milestone.title)
        expect_issues_list_count(1)
        expect_search_term(search_term)
      end

      it 'filters issues by searched label, label2, author, assignee, not included in a milestone' do
        search_term = 'bug'
        select_tokens 'Label', '=', bug_label.title, 'Label', '=', caps_sensitive_label.title, 'Author', '=', user.username, 'Assignee', '=', user.username, 'Milestone', '!=', milestone.title
        send_keys search_term, :enter, :enter

        expect_label_token(bug_label.title)
        expect_label_token(caps_sensitive_label.title)
        expect_author_token(user.name)
        expect_assignee_token(user.name)
        expect_negated_milestone_token(milestone.title)
        expect_issues_list_count(0)
        expect_search_term(search_term)
      end
    end

    context 'issue label clicked' do
      it 'filters and displays in search bar' do
        click_link multiple_words_label.title

        expect_issues_list_count(1)
        expect_label_token(multiple_words_label.title)
        expect_empty_search_term
      end
    end
  end

  describe 'filter issues by milestone' do
    context 'only milestone' do
      it 'filters issues by searched milestone' do
        select_tokens 'Milestone', '=', milestone.title, submit: true

        expect_milestone_token(milestone.title)
        expect_issues_list_count(5)
        expect_empty_search_term
      end

      it 'filters issues by no milestone' do
        select_tokens 'Milestone', '=', 'None', submit: true

        expect_milestone_token 'None'
        expect_issues_list_count(3)
        expect_empty_search_term
      end

      it 'filters issues by upcoming milestones' do
        create(:milestone, project: project, due_date: 1.month.from_now) do |future_milestone|
          create(:issue, project: project, milestone: future_milestone, author: user)
        end

        select_tokens 'Milestone', '=', 'Upcoming', submit: true

        expect_milestone_token 'Upcoming'
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'filters issues by negation of upcoming milestones' do
        create(:milestone, project: project, due_date: 1.month.from_now) do |future_milestone|
          create(:issue, project: project, milestone: future_milestone, author: user)
        end

        create(:milestone, project: project, due_date: 3.days.ago) do |past_milestone|
          create(:issue, project: project, milestone: past_milestone, author: user)
        end

        select_tokens 'Milestone', '!=', 'Upcoming', submit: true

        expect_negated_milestone_token 'Upcoming'
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'filters issues by started milestones' do
        select_tokens 'Milestone', '=', 'Started', submit: true

        expect_milestone_token 'Started'
        expect_issues_list_count(5)
        expect_empty_search_term
      end

      it 'filters issues by negation of started milestones' do
        milestone2 = create(:milestone, title: "9", project: project, start_date: 2.weeks.from_now)
        create(:issue, project: project, author: user, title: "something else", milestone: milestone2)

        select_tokens 'Milestone', '!=', 'Started', submit: true

        expect_negated_milestone_token 'Started'
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'filters issues by milestone containing special characters' do
        special_milestone = create(:milestone, title: '!@\#{$%^&*()}', project: project)
        create(:issue, project: project, milestone: special_milestone)

        select_tokens 'Milestone', '=', special_milestone.title, submit: true

        expect_milestone_token(special_milestone.title)
        expect_issues_list_count(1)
        expect_empty_search_term
      end

      it 'filters issues by milestone not containing special characters' do
        special_milestone = create(:milestone, title: '!@\#{$%^&*()}', project: project)
        create(:issue, project: project, milestone: special_milestone)

        select_tokens 'Milestone', '!=', special_milestone.title, submit: true

        expect_negated_milestone_token(special_milestone.title)
        expect_issues_list_count(8)
        expect_empty_search_term
      end

      it 'does not show issues for unused milestones' do
        new_milestone = create(:milestone, title: 'new', project: project)

        select_tokens 'Milestone', '=', new_milestone.title, submit: true

        expect_milestone_token(new_milestone.title)
        expect_no_issues_list
        expect_empty_search_term
      end

      it 'show issues for unused milestones' do
        new_milestone = create(:milestone, title: 'new', project: project)

        select_tokens 'Milestone', '!=', new_milestone.title, submit: true

        expect_negated_milestone_token(new_milestone.title)
        expect_issues_list_count(8)
        expect_empty_search_term
      end
    end
  end

  describe 'filter issues by text' do
    context 'only text' do
      it 'filters issues by searched text' do
        search = 'Bug'
        submit_search_term(search)

        expect_issues_list_count(4)
        expect_search_term(search)
      end

      it 'filters issues by multiple searched text' do
        search = 'Bug report'
        submit_search_term(search)

        expect_issues_list_count(3)
        expect_search_term(search)
      end

      it 'filters issues by case insensitive searched text' do
        search = 'bug report'
        submit_search_term(search)

        expect_issues_list_count(3)
        expect_search_term(search)
      end

      it 'filters issues by searched text containing single quotes' do
        issue = create(:issue, project: project, author: user, title: "issue with 'single quotes'")

        search = 'single quotes'
        submit_search_term "'#{search}'"

        expect_issues_list_count(1)
        expect_search_term(search)
        expect(page).to have_content(issue.title)
      end

      it 'filters issues by searched text containing double quotes' do
        issue = create(:issue, project: project, author: user, title: "issue with \"double quotes\"")

        search = 'double quotes'
        submit_search_term "\"#{search}\""

        expect_issues_list_count(1)
        expect_search_term(search)
        expect(page).to have_content(issue.title)
      end

      it 'does not show any issues' do
        search = 'testing'
        submit_search_term(search)

        expect_no_issues_list
        expect_search_term(search)
      end

      it 'filters issues by issue reference' do
        search = '#1'
        submit_search_term(search)

        expect_issues_list_count(1)
        expect_search_term(search)
      end
    end

    context 'searched text with other filters' do
      it 'filters issues by searched text, author, text, assignee, text, label1, text, label2, text, milestone and text' do
        click_filtered_search_bar
        send_keys 'bug', :enter
        select_tokens 'Author', '=', user.username
        send_keys 'report', :enter
        select_tokens 'Label', '=', bug_label.title
        select_tokens 'Label', '=', caps_sensitive_label.title
        select_tokens 'Milestone', '=', milestone.title
        send_keys 'foo', :enter, :enter

        expect_issues_list_count(1)
        expect_search_term('bug report foo')
      end
    end

    context 'sorting' do
      it 'sorts by created date' do
        new_issue = create(:issue,
          title: '3 days ago',
          project: project,
          author: user,
          created_at: 3.days.ago)

        create(:issue,
          title: '5 days ago',
          project: project,
          author: user,
          created_at: 5.days.ago)

        submit_search_term 'days ago'

        expect_issues_list_count(2)
        expect(page).to have_button 'Created date'
        expect(page).to have_css('.issue:first-of-type .issue-title', text: new_issue.title)
      end
    end
  end

  describe 'switching issue states' do
    let!(:closed_issue) { create(:issue, :closed, project: project, title: 'closed bug') }

    before do
      submit_search_term 'bug'

      # This ensures that the search is performed
      expect_issues_list_count(4, 1)
    end

    it 'maintains filter' do
      click_link 'Closed'
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 1)
      expect(page).to have_link(closed_issue.title)

      click_link 'Open'
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 4)

      click_link 'All'
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 5)
    end
  end

  context 'URL has a trailing slash' do
    before do
      visit "#{project_issues_path(project)}/"
    end

    it 'milestone dropdown loads milestones' do
      select_tokens 'Milestone', '='

      # Expect None, Any, Upcoming, Started, 8
      expect_suggestion_count 5
    end

    it 'label dropdown load labels' do
      select_tokens 'Label', '='

      # Dropdown shows None, Any, and 3 labels
      expect_suggestion_count 5
    end
  end
end
