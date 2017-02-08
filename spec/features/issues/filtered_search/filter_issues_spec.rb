require 'rails_helper'

describe 'Filter issues', js: true, feature: true do
  include WaitForAjax

  let!(:group) { create(:group) }
  let!(:project) { create(:project, group: group) }
  let!(:user) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label) { create(:label, project: project) }
  let!(:wontfix) { create(:label, project: project, title: "Won't fix") }

  let!(:bug_label) { create(:label, project: project, title: 'bug') }
  let!(:caps_sensitive_label) { create(:label, project: project, title: 'CAPS_sensitive') }
  let!(:milestone) { create(:milestone, title: "8", project: project) }
  let!(:multiple_words_label) { create(:label, project: project, title: "Two words") }

  let!(:closed_issue) { create(:issue, title: 'bug that is closed', project: project, state: :closed) }
  let(:filtered_search) { find('.filtered-search') }

  def input_filtered_search(search_term, submit: true)
    filtered_search.set(search_term)

    if submit
      filtered_search.send_keys(:enter)
    end
  end

  def expect_filtered_search_input(input)
    expect(find('.filtered-search').value).to eq(input)
  end

  def expect_no_issues_list
    page.within '.issues-list' do
      expect(page).not_to have_selector('.issue')
    end
  end

  def expect_issues_list_count(open_count, closed_count = 0)
    all_count = open_count + closed_count

    expect(page).to have_issuable_counts(open: open_count, closed: closed_count, all: all_count)
    page.within '.issues-list' do
      expect(page).to have_selector('.issue', count: open_count)
    end
  end

  def select_search_at_index(pos)
    evaluate_script("el = document.querySelector('.filtered-search'); el.focus(); el.setSelectionRange(#{pos}, #{pos});")
  end

  before do
    project.team << [user, :master]
    project.team << [user2, :master]
    group.add_developer(user)
    group.add_developer(user2)
    login_as(user)
    create(:issue, project: project)

    create(:issue, title: "Bug report 1", project: project)
    create(:issue, title: "Bug report 2", project: project)
    create(:issue, title: "issue with 'single quotes'", project: project)
    create(:issue, title: "issue with \"double quotes\"", project: project)
    create(:issue, title: "issue with !@\#{$%^&*()-+", project: project)
    create(:issue, title: "issue by assignee", project: project, milestone: milestone, author: user, assignee: user)
    create(:issue, title: "issue by assignee with searchTerm", project: project, milestone: milestone, author: user, assignee: user)

    issue = create(:issue,
      title: "Bug 2",
      project: project,
      milestone: milestone,
      author: user,
      assignee: user)
    issue.labels << bug_label

    issue_with_caps_label = create(:issue,
      title: "issue by assignee with searchTerm and label",
      project: project,
      milestone: milestone,
      author: user,
      assignee: user)
    issue_with_caps_label.labels << caps_sensitive_label

    issue_with_everything = create(:issue,
      title: "Bug report with everything you thought was possible",
      project: project,
      milestone: milestone,
      author: user,
      assignee: user)
    issue_with_everything.labels << bug_label
    issue_with_everything.labels << caps_sensitive_label

    multiple_words_label_issue = create(:issue, title: "Issue with multiple words label", project: project)
    multiple_words_label_issue.labels << multiple_words_label

    future_milestone = create(:milestone, title: "future", project: project, due_date: Time.now + 1.month)

    create(:issue,
      title: "Issue with future milestone",
      milestone: future_milestone,
      project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'filter issues by author' do
    context 'only author' do
      it 'filters issues by searched author' do
        input_filtered_search("author:@#{user.username}")

        expect_issues_list_count(5)
      end

      it 'filters issues by invalid author' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end

      it 'filters issues by multiple authors' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end
    end

    context 'author with other filters' do
      it 'filters issues by searched author and text' do
        search = "author:@#{user.username} issue"
        input_filtered_search(search)

        expect_issues_list_count(3)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched author, assignee and text' do
        search = "author:@#{user.username} assignee:@#{user.username} issue"
        input_filtered_search(search)

        expect_issues_list_count(3)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched author, assignee, label, and text' do
        search = "author:@#{user.username} assignee:@#{user.username} label:~#{caps_sensitive_label.title} issue"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched author, assignee, label, milestone and text' do
        search = "author:@#{user.username} assignee:@#{user.username} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} issue"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end
    end

    it 'sorting' do
      pending('to be tested, issue #26546')
      expect(true).to be(false)
    end
  end

  describe 'filter issues by assignee' do
    context 'only assignee' do
      it 'filters issues by searched assignee' do
        search = "assignee:@#{user.username}"
        input_filtered_search(search)

        expect_issues_list_count(5)
        expect_filtered_search_input(search)
      end

      it 'filters issues by no assignee' do
        search = "assignee:none"
        input_filtered_search(search)

        expect_issues_list_count(8, 1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by invalid assignee' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end

      it 'filters issues by multiple assignees' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end
    end

    context 'assignee with other filters' do
      it 'filters issues by searched assignee and text' do
        search = "assignee:@#{user.username} searchTerm"
        input_filtered_search(search)

        expect_issues_list_count(2)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched assignee, author and text' do
        search = "assignee:@#{user.username} author:@#{user.username} searchTerm"
        input_filtered_search(search)

        expect_issues_list_count(2)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched assignee, author, label, text' do
        search = "assignee:@#{user.username} author:@#{user.username} label:~#{caps_sensitive_label.title} searchTerm"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched assignee, author, label, milestone and text' do
        search = "assignee:@#{user.username} author:@#{user.username} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} searchTerm"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end
    end

    context 'sorting' do
      it 'sorts' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end
    end
  end

  describe 'filter issues by label' do
    context 'only label' do
      it 'filters issues by searched label' do
        search = "label:~#{bug_label.title}"
        input_filtered_search(search)

        expect_issues_list_count(2)
        expect_filtered_search_input(search)
      end

      it 'filters issues by no label' do
        search = "label:none"
        input_filtered_search(search)

        expect_issues_list_count(9, 1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by invalid label' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end

      it 'filters issues by multiple labels' do
        search = "label:~#{bug_label.title} label:~#{caps_sensitive_label.title}"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by label containing special characters' do
        special_label = create(:label, project: project, title: '!@#{$%^&*()-+[]<>?/:{}|\}')
        special_issue = create(:issue, title: "Issue with special character label", project: project)
        special_issue.labels << special_label

        search = "label:~#{special_label.title}"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'does not show issues' do
        new_label = create(:label, project: project, title: "new_label")

        search = "label:~#{new_label.title}"
        input_filtered_search(search)

        expect_no_issues_list()
        expect_filtered_search_input(search)
      end
    end

    context 'label with multiple words' do
      it 'special characters' do
        special_multiple_label = create(:label, project: project, title: "Utmost |mp0rt@nce")
        special_multiple_issue = create(:issue, title: "Issue with special character multiple words label", project: project)
        special_multiple_issue.labels << special_multiple_label

        search = "label:~'#{special_multiple_label.title}'"
        input_filtered_search(search)

        expect_issues_list_count(1)

        # filtered search defaults quotations to double quotes
        expect_filtered_search_input("label:~\"#{special_multiple_label.title}\"")
      end

      it 'single quotes' do
        search = "label:~'#{multiple_words_label.title}'"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input("label:~\"#{multiple_words_label.title}\"")
      end

      it 'double quotes' do
        search = "label:~\"#{multiple_words_label.title}\""
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'single quotes containing double quotes' do
        double_quotes_label = create(:label, project: project, title: 'won"t fix')
        double_quotes_label_issue = create(:issue, title: "Issue with double quotes label", project: project)
        double_quotes_label_issue.labels << double_quotes_label

        search = "label:~'#{double_quotes_label.title}'"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'double quotes containing single quotes' do
        single_quotes_label = create(:label, project: project, title: "won't fix")
        single_quotes_label_issue = create(:issue, title: "Issue with single quotes label", project: project)
        single_quotes_label_issue.labels << single_quotes_label

        search = "label:~\"#{single_quotes_label.title}\""
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end
    end

    context 'label with other filters' do
      it 'filters issues by searched label and text' do
        search = "label:~#{caps_sensitive_label.title} bug"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched label, author and text' do
        search = "label:~#{caps_sensitive_label.title} author:@#{user.username} bug"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched label, author, assignee and text' do
        search = "label:~#{caps_sensitive_label.title} author:@#{user.username} assignee:@#{user.username} bug"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched label, author, assignee, milestone and text' do
        search = "label:~#{caps_sensitive_label.title} author:@#{user.username} assignee:@#{user.username} milestone:%#{milestone.title} bug"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end
    end

    context 'multiple labels with other filters' do
      it 'filters issues by searched label, label2, and text' do
        search = "label:~#{bug_label.title} label:~#{caps_sensitive_label.title} bug"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched label, label2, author and text' do
        search = "label:~#{bug_label.title} label:~#{caps_sensitive_label.title} author:@#{user.username} bug"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched label, label2, author, assignee and text' do
        search = "label:~#{bug_label.title} label:~#{caps_sensitive_label.title} author:@#{user.username} assignee:@#{user.username} bug"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched label, label2, author, assignee, milestone and text' do
        search = "label:~#{bug_label.title} label:~#{caps_sensitive_label.title} author:@#{user.username} assignee:@#{user.username} milestone:%#{milestone.title} bug"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end
    end

    context 'issue label clicked' do
      before do
        find('.issues-list .issue .issue-info a .label', text: multiple_words_label.title).click
        sleep 1
      end

      it 'filters' do
        expect_issues_list_count(1)
      end

      it 'displays in search bar' do
        expect(find('.filtered-search').value).to eq("label:~\"#{multiple_words_label.title}\"")
      end
    end

    context 'sorting' do
      it 'sorts' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end
    end
  end

  describe 'filter issues by milestone' do
    context 'only milestone' do
      it 'filters issues by searched milestone' do
        input_filtered_search("milestone:%#{milestone.title}")

        expect_issues_list_count(5)
      end

      it 'filters issues by no milestone' do
        input_filtered_search("milestone:none")

        expect_issues_list_count(7, 1)
      end

      it 'filters issues by upcoming milestones' do
        input_filtered_search("milestone:upcoming")

        expect_issues_list_count(1)
      end

      it 'filters issues by invalid milestones' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end

      it 'filters issues by multiple milestones' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end

      it 'filters issues by milestone containing special characters' do
        special_milestone = create(:milestone, title: '!@\#{$%^&*()}', project: project)
        create(:issue, title: "Issue with special character milestone", project: project, milestone: special_milestone)

        search = "milestone:%#{special_milestone.title}"
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'does not show issues' do
        new_milestone = create(:milestone, title: "new", project: project)

        search = "milestone:%#{new_milestone.title}"
        input_filtered_search(search)

        expect_no_issues_list()
        expect_filtered_search_input(search)
      end
    end

    context 'milestone with other filters' do
      it 'filters issues by searched milestone and text' do
        search = "milestone:%#{milestone.title} bug"
        input_filtered_search(search)

        expect_issues_list_count(2)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched milestone, author and text' do
        search = "milestone:%#{milestone.title} author:@#{user.username} bug"
        input_filtered_search(search)

        expect_issues_list_count(2)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched milestone, author, assignee and text' do
        search = "milestone:%#{milestone.title} author:@#{user.username} assignee:@#{user.username} bug"
        input_filtered_search(search)

        expect_issues_list_count(2)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched milestone, author, assignee, label and text' do
        search = "milestone:%#{milestone.title} author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} bug"
        input_filtered_search(search)

        expect_issues_list_count(2)
        expect_filtered_search_input(search)
      end
    end

    context 'sorting' do
      it 'sorts' do
        pending('to be tested, issue #26546')
        expect(true).to be(false)
      end
    end
  end

  describe 'overwrites selected filter' do
    it 'changes author' do
      input_filtered_search("author:@#{user.username}", submit: false)

      select_search_at_index(3)

      page.within '#js-dropdown-author' do
        click_button user2.username
      end

      expect(filtered_search.value).to eq("author:@#{user2.username} ")
    end

    it 'changes label' do
      input_filtered_search("author:@#{user.username} label:~#{bug_label.title}", submit: false)

      select_search_at_index(27)

      page.within '#js-dropdown-label' do
        click_button label.name
      end

      expect(filtered_search.value).to eq("author:@#{user.username} label:~#{label.name} ")
    end

    it 'changes label correctly space is in previous label' do
      input_filtered_search("label:~\"#{multiple_words_label.title}\"", submit: false)

      select_search_at_index(0)

      page.within '#js-dropdown-label' do
        click_button label.name
      end

      expect(filtered_search.value).to eq("label:~#{label.name} ")
    end
  end

  describe 'filter issues by text' do
    context 'only text' do
      it 'filters issues by searched text' do
        search = 'Bug'
        input_filtered_search(search)

        expect_issues_list_count(4, 1)
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
        search = '\'single quotes\''
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched text containing double quotes' do
        search = '"double quotes"'
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'filters issues by searched text containing special characters' do
        search = '!@#{$%^&*()-+'
        input_filtered_search(search)

        expect_issues_list_count(1)
        expect_filtered_search_input(search)
      end

      it 'does not show any issues' do
        search = 'testing'
        input_filtered_search(search)

        expect_no_issues_list()
        expect_filtered_search_input(search)
      end
    end

    context 'searched text with other filters' do
      it 'filters issues by searched text and author' do
        input_filtered_search("bug author:@#{user.username}")

        expect_issues_list_count(2)
        expect_filtered_search_input("author:@#{user.username} bug")
      end

      it 'filters issues by searched text, author and more text' do
        input_filtered_search("bug author:@#{user.username} report")

        expect_issues_list_count(1)
        expect_filtered_search_input("author:@#{user.username} bug report")
      end

      it 'filters issues by searched text, author and assignee' do
        input_filtered_search("bug author:@#{user.username} assignee:@#{user.username}")

        expect_issues_list_count(2)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} bug")
      end

      it 'filters issues by searched text, author, more text and assignee' do
        input_filtered_search("bug author:@#{user.username} report assignee:@#{user.username}")

        expect_issues_list_count(1)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} bug report")
      end

      it 'filters issues by searched text, author, more text, assignee and even more text' do
        input_filtered_search("bug author:@#{user.username} report assignee:@#{user.username} with")

        expect_issues_list_count(1)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} bug report with")
      end

      it 'filters issues by searched text, author, assignee and label' do
        input_filtered_search("bug author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title}")

        expect_issues_list_count(2)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} bug")
      end

      it 'filters issues by searched text, author, text, assignee, text, label and text' do
        input_filtered_search("bug author:@#{user.username} report assignee:@#{user.username} with label:~#{bug_label.title} everything")

        expect_issues_list_count(1)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} bug report with everything")
      end

      it 'filters issues by searched text, author, assignee, label and milestone' do
        input_filtered_search("bug author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} milestone:%#{milestone.title}")

        expect_issues_list_count(2)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} milestone:%#{milestone.title} bug")
      end

      it 'filters issues by searched text, author, text, assignee, text, label, text, milestone and text' do
        input_filtered_search("bug author:@#{user.username} report assignee:@#{user.username} with label:~#{bug_label.title} everything milestone:%#{milestone.title} you")

        expect_issues_list_count(1)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} milestone:%#{milestone.title} bug report with everything you")
      end

      it 'filters issues by searched text, author, assignee, multiple labels and milestone' do
        input_filtered_search("bug author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title}")

        expect_issues_list_count(1)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} bug")
      end

      it 'filters issues by searched text, author, text, assignee, text, label1, text, label2, text, milestone and text' do
        input_filtered_search("bug author:@#{user.username} report assignee:@#{user.username} with label:~#{bug_label.title} everything label:~#{caps_sensitive_label.title} you milestone:%#{milestone.title} thought")

        expect_issues_list_count(1)
        expect_filtered_search_input("author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} bug report with everything you thought")
      end
    end

    context 'sorting' do
      it 'sorts by oldest updated' do
        create(:issue,
          title: '3 days ago',
          project: project,
          author: user,
          created_at: 3.days.ago,
          updated_at: 3.days.ago)

        old_issue = create(:issue,
          title: '5 days ago',
          project: project,
          author: user,
          created_at: 5.days.ago,
          updated_at: 5.days.ago)

        input_filtered_search('days ago')

        expect_issues_list_count(2)

        sort_toggle = find('.filtered-search-container .dropdown-toggle')
        sort_toggle.click

        find('.filtered-search-container .dropdown-menu li a', text: 'Oldest updated').click
        wait_for_ajax

        expect(find('.issues-list .issue:first-of-type .issue-title-text a')).to have_content(old_issue.title)
      end
    end
  end

  describe 'retains filter when switching issue states' do
    before do
      input_filtered_search('bug')

      # Wait for search results to load
      sleep 2
    end

    it 'open state' do
      find('.issues-state-filters a', text: 'Closed').click
      wait_for_ajax

      find('.issues-state-filters a', text: 'Open').click
      wait_for_ajax

      expect(page).to have_selector('.issues-list .issue', count: 4)
    end

    it 'closed state' do
      find('.issues-state-filters a', text: 'Closed').click
      wait_for_ajax

      expect(page).to have_selector('.issues-list .issue', count: 1)
      expect(find('.issues-list .issue:first-of-type .issue-title-text a')).to have_content(closed_issue.title)
    end

    it 'all state' do
      find('.issues-state-filters a', text: 'All').click
      wait_for_ajax

      expect(page).to have_selector('.issues-list .issue', count: 5)
    end
  end

  describe 'RSS feeds' do
    it 'updates atom feed link for project issues' do
      visit namespace_project_issues_path(project.namespace, project, milestone_title: milestone.title, assignee_id: user.id)
      link = find('.nav-controls a', text: 'Subscribe')
      params = CGI.parse(URI.parse(link[:href]).query)
      auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
      auto_discovery_params = CGI.parse(URI.parse(auto_discovery_link[:href]).query)

      expect(params).to include('private_token' => [user.private_token])
      expect(params).to include('milestone_title' => [milestone.title])
      expect(params).to include('assignee_id' => [user.id.to_s])
      expect(auto_discovery_params).to include('private_token' => [user.private_token])
      expect(auto_discovery_params).to include('milestone_title' => [milestone.title])
      expect(auto_discovery_params).to include('assignee_id' => [user.id.to_s])
    end

    it 'updates atom feed link for group issues' do
      visit issues_group_path(group, milestone_title: milestone.title, assignee_id: user.id)
      link = find('.nav-controls a', text: 'Subscribe')
      params = CGI.parse(URI.parse(link[:href]).query)
      auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
      auto_discovery_params = CGI.parse(URI.parse(auto_discovery_link[:href]).query)

      expect(params).to include('private_token' => [user.private_token])
      expect(params).to include('milestone_title' => [milestone.title])
      expect(params).to include('assignee_id' => [user.id.to_s])
      expect(auto_discovery_params).to include('private_token' => [user.private_token])
      expect(auto_discovery_params).to include('milestone_title' => [milestone.title])
      expect(auto_discovery_params).to include('assignee_id' => [user.id.to_s])
    end
  end

  context 'URL has a trailing slash' do
    before do
      visit "#{namespace_project_issues_path(project.namespace, project)}/"
    end

    it 'milestone dropdown loads milestones' do
      input_filtered_search("milestone:", submit: false)

      within('#js-dropdown-milestone') do
        expect(page).to have_selector('.filter-dropdown .filter-dropdown-item', count: 2)
      end
    end

    it 'label dropdown load labels' do
      input_filtered_search("label:", submit: false)

      within('#js-dropdown-label') do
        expect(page).to have_selector('.filter-dropdown .filter-dropdown-item', count: 5)
      end
    end
  end
end
