# frozen_string_literal: true

require 'spec_helper'

describe 'Filter issues', :js do
  include FilteredSearchHelpers

  let(:project) { create(:project) }

  # NOTE: The short name here is actually important
  #
  # When the name is longer, the filtered search input can end up scrolling
  # horizontally, and PhantomJS can't handle it.
  let(:user) { create(:user, name: 'Ann') }
  let(:user2) { create(:user, name: 'jane') }

  let!(:bug_label) { create(:label, project: project, title: 'bug') }
  let!(:caps_sensitive_label) { create(:label, project: project, title: 'CaPs') }
  let!(:multiple_words_label) { create(:label, project: project, title: "Two words") }
  let!(:milestone) { create(:milestone, title: "8", project: project, start_date: 2.days.ago) }

  def expect_no_issues_list
    page.within '.issues-list' do
      expect(page).to have_no_selector('.issue')
    end
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

    input_filtered_search("assignee:@#{user.username} author:@#{user.username} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} #{search_term}")

    wait_for_requests

    expect_tokens([
      assignee_token(user.name),
      author_token(user.name),
      label_token(caps_sensitive_label.title),
      milestone_token(milestone.title)
    ])
    expect_issues_list_count(1)
    expect_filtered_search_input(search_term)
  end

  describe 'filter issues by author' do
    context 'only author' do
      it 'filters issues by searched author' do
        input_filtered_search("author:@#{user.username}")

        wait_for_requests

        expect_tokens([author_token(user.name)])
        expect_issues_list_count(5)
        expect_filtered_search_input_empty
      end
    end
  end

  describe 'filter issues by assignee' do
    context 'only assignee' do
      it 'filters issues by searched assignee' do
        input_filtered_search("assignee:@#{user.username}")

        wait_for_requests

        expect_tokens([assignee_token(user.name)])
        expect_issues_list_count(5)
        expect_filtered_search_input_empty
      end

      it 'filters issues by no assignee' do
        input_filtered_search('assignee:none')

        expect_tokens([assignee_token('None')])
        expect_issues_list_count(3)
        expect_filtered_search_input_empty
      end

      it 'filters issues by invalid assignee' do
        skip('to be tested, issue #26546')
      end

      it 'filters issues by multiple assignees' do
        create(:issue, project: project, author: user, assignees: [user2, user])

        input_filtered_search("assignee:@#{user.username} assignee:@#{user2.username}")

        expect_tokens([
          assignee_token(user.name),
          assignee_token(user2.name)
        ])

        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end
    end
  end

  describe 'filter issues by label' do
    context 'only label' do
      it 'filters issues by searched label' do
        input_filtered_search("label:~#{bug_label.title}")

        expect_tokens([label_token(bug_label.title)])
        expect_issues_list_count(2)
        expect_filtered_search_input_empty
      end

      it 'filters issues by no label' do
        input_filtered_search('label:none')

        expect_tokens([label_token('None', false)])
        expect_issues_list_count(4)
        expect_filtered_search_input_empty
      end

      it 'filters issues by multiple labels' do
        input_filtered_search("label:~#{bug_label.title} label:~#{caps_sensitive_label.title}")

        expect_tokens([
          label_token(bug_label.title),
          label_token(caps_sensitive_label.title)
        ])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end

      it 'filters issues by label containing special characters' do
        special_label = create(:label, project: project, title: '!@#{$%^&*()-+[]<>?/:{}|\}')
        special_issue = create(:issue, title: "Issue with special character label", project: project)
        special_issue.labels << special_label

        input_filtered_search("label:~#{special_label.title}")

        expect_tokens([label_token(special_label.title)])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end

      it 'does not show issues for unused labels' do
        new_label = create(:label, project: project, title: 'new_label')

        input_filtered_search("label:~#{new_label.title}")

        expect_tokens([label_token(new_label.title)])
        expect_no_issues_list
        expect_filtered_search_input_empty
      end
    end

    context 'label with multiple words' do
      it 'special characters' do
        special_multiple_label = create(:label, project: project, title: "Utmost |mp0rt@nce")
        special_multiple_issue = create(:issue, title: "Issue with special character multiple words label", project: project)
        special_multiple_issue.labels << special_multiple_label

        input_filtered_search("label:~'#{special_multiple_label.title}'")

        # Check for search results (which makes sure that the page has changed)
        expect_issues_list_count(1)

        # filtered search defaults quotations to double quotes
        expect_tokens([label_token("\"#{special_multiple_label.title}\"")])

        expect_filtered_search_input_empty
      end

      it 'single quotes' do
        input_filtered_search("label:~'#{multiple_words_label.title}'")

        expect_issues_list_count(1)
        expect_tokens([label_token("\"#{multiple_words_label.title}\"")])
        expect_filtered_search_input_empty
      end

      it 'double quotes' do
        input_filtered_search("label:~\"#{multiple_words_label.title}\"")

        expect_tokens([label_token("\"#{multiple_words_label.title}\"")])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end

      it 'single quotes containing double quotes' do
        double_quotes_label = create(:label, project: project, title: 'won"t fix')
        double_quotes_label_issue = create(:issue, title: "Issue with double quotes label", project: project)
        double_quotes_label_issue.labels << double_quotes_label

        input_filtered_search("label:~'#{double_quotes_label.title}'")

        expect_tokens([label_token("'#{double_quotes_label.title}'")])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end

      it 'double quotes containing single quotes' do
        single_quotes_label = create(:label, project: project, title: "won't fix")
        single_quotes_label_issue = create(:issue, title: "Issue with single quotes label", project: project)
        single_quotes_label_issue.labels << single_quotes_label

        input_filtered_search("label:~\"#{single_quotes_label.title}\"")

        expect_tokens([label_token("\"#{single_quotes_label.title}\"")])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end
    end

    context 'multiple labels with other filters' do
      it 'filters issues by searched label, label2, author, assignee, milestone and text' do
        search_term = 'bug'

        input_filtered_search("label:~#{bug_label.title} label:~#{caps_sensitive_label.title} author:@#{user.username} assignee:@#{user.username} milestone:%#{milestone.title} #{search_term}")

        wait_for_requests

        expect_tokens([
          label_token(bug_label.title),
          label_token(caps_sensitive_label.title),
          author_token(user.name),
          assignee_token(user.name),
          milestone_token(milestone.title)
        ])
        expect_issues_list_count(1)
        expect_filtered_search_input(search_term)
      end
    end

    context 'issue label clicked' do
      it 'filters and displays in search bar' do
        find('.issues-list .issue .issuable-main-info .issuable-info a .badge', text: multiple_words_label.title).click

        expect_issues_list_count(1)
        expect_tokens([label_token("\"#{multiple_words_label.title}\"")])
        expect_filtered_search_input_empty
      end
    end
  end

  describe 'filter issues by milestone' do
    context 'only milestone' do
      it 'filters issues by searched milestone' do
        input_filtered_search("milestone:%#{milestone.title}")

        expect_tokens([milestone_token(milestone.title)])
        expect_issues_list_count(5)
        expect_filtered_search_input_empty
      end

      it 'filters issues by no milestone' do
        input_filtered_search("milestone:none")

        expect_tokens([milestone_token('None', false)])
        expect_issues_list_count(3)
        expect_filtered_search_input_empty
      end

      it 'filters issues by upcoming milestones' do
        create(:milestone, project: project, due_date: 1.month.from_now) do |future_milestone|
          create(:issue, project: project, milestone: future_milestone, author: user)
        end

        input_filtered_search("milestone:upcoming")

        expect_tokens([milestone_token('Upcoming', false)])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end

      it 'filters issues by started milestones' do
        input_filtered_search("milestone:started")

        expect_tokens([milestone_token('Started', false)])
        expect_issues_list_count(5)
        expect_filtered_search_input_empty
      end

      it 'filters issues by milestone containing special characters' do
        special_milestone = create(:milestone, title: '!@\#{$%^&*()}', project: project)
        create(:issue, project: project, milestone: special_milestone)

        input_filtered_search("milestone:%#{special_milestone.title}")

        expect_tokens([milestone_token(special_milestone.title)])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end

      it 'does not show issues for unused milestones' do
        new_milestone = create(:milestone, title: 'new', project: project)

        input_filtered_search("milestone:%#{new_milestone.title}")

        expect_tokens([milestone_token(new_milestone.title)])
        expect_no_issues_list
        expect_filtered_search_input_empty
      end
    end
  end

  describe 'filter issues by text' do
    context 'only text' do
      it 'filters issues by searched text' do
        search = 'Bug'
        input_filtered_search(search)

        expect_issues_list_count(4)
        expect_filtered_search_input(search)
      end

      it 'filters issues by multiple searched text' do
        search = 'Bug report'
        input_filtered_search(search)

        expect_issues_list_count(3)
        expect_filtered_search_input(search)
      end

      it 'filters issues by case insensitive searched text' do
        search = 'bug report'
        input_filtered_search(search)

        expect_issues_list_count(3)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched text containing single quotes' do
        issue = create(:issue, project: project, author: user, title: "issue with 'single quotes'")

        search = "'single quotes'"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
        expect(page).to have_content(issue.title)
      end

      it 'filters issues by searched text containing double quotes' do
        issue = create(:issue, project: project, author: user, title: "issue with \"double quotes\"")

        search = '"double quotes"'
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
        expect(page).to have_content(issue.title)
      end

      it 'filters issues by searched text containing special characters' do
        issue = create(:issue, project: project, author: user, title: "issue with !@\#{$%^&*()-+")

        search = '!@#{$%^&*()-+'
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
        expect(page).to have_content(issue.title)
      end

      it 'does not show any issues' do
        search = 'testing'
        input_filtered_search(search)

        expect_no_issues_list
        expect_filtered_search_input(search)
      end
    end

    context 'searched text with other filters' do
      it 'filters issues by searched text, author, text, assignee, text, label1, text, label2, text, milestone and text' do
        input_filtered_search("bug author:@#{user.username} report label:~#{bug_label.title} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} foo")

        expect_issues_list_count(1)
        expect_filtered_search_input('bug report foo')
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

        input_filtered_search('days ago')

        expect_issues_list_count(2)

        sort_toggle = find('.filter-dropdown-container .dropdown')
        sort_toggle.click

        find('.filter-dropdown-container .dropdown-menu li a', text: 'Created date').click
        wait_for_requests

        expect(find('.issues-list .issue:first-of-type .issue-title-text a')).to have_content(new_issue.title)
      end
    end
  end

  describe 'switching issue states' do
    let!(:closed_issue) { create(:issue, :closed, project: project, title: 'closed bug') }

    before do
      input_filtered_search('bug')

      # This ensures that the search is performed
      expect_issues_list_count(4, 1)
    end

    it 'maintains filter' do
      # Closed
      find('.issues-state-filters [data-state="closed"]').click
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 1)
      expect(page).to have_link(closed_issue.title)

      # Opened
      find('.issues-state-filters [data-state="opened"]').click
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 4)

      # All
      find('.issues-state-filters [data-state="all"]').click
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 5)
    end
  end

  context 'URL has a trailing slash' do
    before do
      visit "#{project_issues_path(project)}/"
    end

    it 'milestone dropdown loads milestones' do
      input_filtered_search("milestone:", submit: false)

      within('#js-dropdown-milestone') do
        expect(page).to have_selector('.filter-dropdown .filter-dropdown-item', count: 1)
      end
    end

    it 'label dropdown load labels' do
      input_filtered_search("label:", submit: false)

      within('#js-dropdown-label') do
        expect(page).to have_selector('.filter-dropdown .filter-dropdown-item', count: 3)
      end
    end
  end
end
