require 'spec_helper'

describe 'Filter issues', js: true do
  include FilteredSearchHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  let!(:label) { create(:label, project: project) }
  let!(:wontfix) { create(:label, project: project, title: "Won't fix") }

  let!(:bug_label) { create(:label, project: project, title: 'bug') }
  let!(:caps_sensitive_label) { create(:label, project: project, title: 'CaPs') }
  let!(:milestone) { create(:milestone, title: "8", project: project, start_date: 2.days.ago) }
  let!(:multiple_words_label) { create(:label, project: project, title: "Two words") }

  let!(:closed_issue) { create(:issue, title: 'bug that is closed', project: project, state: :closed) }

  def expect_no_issues_list
    page.within '.issues-list' do
      expect(page).to have_no_selector('.issue')
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
    project.add_master(user)

    user2 = create(:user)

    create(:issue, project: project, author: user2, title: "Bug report 1")
    create(:issue, project: project, author: user2, title: "Bug report 2")
    create(:issue, project: project, author: user2, title: "issue with 'single quotes'")
    create(:issue, project: project, author: user2, title: "issue with \"double quotes\"")
    create(:issue, project: project, author: user2, title: "issue with !@\#{$%^&*()-+")

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

    create(:milestone, project: project, due_date: 1.month.from_now) do |future_milestone|
      create(:issue, project: project, milestone: future_milestone, author: user2)
    end

    sign_in(user)
    visit project_issues_path(project)
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

    context 'author with other filters' do
      it 'filters issues by searched author, assignee, label, milestone and text' do
        search_term = 'issue'

        input_filtered_search("author:@#{user.username} assignee:@#{user.username} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} #{search_term}")

        wait_for_requests

        expect_tokens([
          author_token(user.name),
          assignee_token(user.name),
          label_token(caps_sensitive_label.title),
          milestone_token(milestone.title)
        ])
        expect_issues_list_count(1)
        expect_filtered_search_input(search_term)
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

        expect_tokens([assignee_token('none')])
        expect_issues_list_count(7, 1)
        expect_filtered_search_input_empty
      end
    end

    context 'assignee with other filters' do
      it 'filters issues by searched assignee, author, label, milestone and text' do
        search_term = 'searchTerm'

        input_filtered_search("assignee:@#{user.username} author:@#{user.username} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} #{search_term}")

        expect_tokens([
          assignee_token(user.name),
          author_token(user.name),
          label_token(caps_sensitive_label.title),
          milestone_token(milestone.title)
        ])
        expect_issues_list_count(1)
        expect_filtered_search_input(search_term)
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

        expect_tokens([label_token('none', false)])
        expect_issues_list_count(8, 1)
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

      it 'does not show issues' do
        new_label = create(:label, project: project, title: 'new_label')

        input_filtered_search("label:~#{new_label.title}")

        expect_tokens([label_token(new_label.title)])
        expect_no_issues_list()
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

    context 'label with other filters' do
      it 'filters issues by searched label, author, assignee, milestone and text' do
        search_term = 'bug'

        input_filtered_search("label:~#{caps_sensitive_label.title} author:@#{user.username} assignee:@#{user.username} milestone:%#{milestone.title} #{search_term}")

        expect_tokens([
          label_token(caps_sensitive_label.title),
          author_token(user.name),
          assignee_token(user.name),
          milestone_token(milestone.title)
        ])
        expect_issues_list_count(1)
        expect_filtered_search_input(search_term)
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
      before do
        find('.issues-list .issue .issue-main-info .issuable-info a .label', text: multiple_words_label.title).click
      end

      it 'filters' do
        expect_issues_list_count(1)
      end

      it 'displays in search bar' do
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

        expect_tokens([milestone_token('none', false)])
        expect_issues_list_count(6, 1)
        expect_filtered_search_input_empty
      end

      it 'filters issues by upcoming milestones' do
        input_filtered_search("milestone:upcoming")

        expect_tokens([milestone_token('upcoming', false)])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end

      it 'filters issues by started milestones' do
        input_filtered_search("milestone:started")

        expect_tokens([milestone_token('started', false)])
        expect_issues_list_count(5)
        expect_filtered_search_input_empty
      end

      it 'filters issues by milestone containing special characters' do
        special_milestone = create(:milestone, title: '!@\#{$%^&*()}', project: project)
        create(:issue, title: "Issue with special character milestone", project: project, milestone: special_milestone)

        input_filtered_search("milestone:%#{special_milestone.title}")

        expect_tokens([milestone_token(special_milestone.title)])
        expect_issues_list_count(1)
        expect_filtered_search_input_empty
      end

      it 'does not show issues' do
        new_milestone = create(:milestone, title: "new", project: project)

        input_filtered_search("milestone:%#{new_milestone.title}")

        expect_tokens([milestone_token(new_milestone.title)])
        expect_no_issues_list()
        expect_filtered_search_input_empty
      end
    end

    context 'milestone with other filters' do
      it 'filters issues by searched milestone, author, assignee, label and text' do
        search_term = 'bug'

        input_filtered_search("milestone:%#{milestone.title} author:@#{user.username} assignee:@#{user.username} label:~#{bug_label.title} #{search_term}")

        wait_for_requests

        expect_tokens([
          milestone_token(milestone.title),
          author_token(user.name),
          assignee_token(user.name),
          label_token(bug_label.title)
        ])
        expect_issues_list_count(2)
        expect_filtered_search_input(search_term)
      end
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
      it 'filters issues by searched text, author, text, assignee, text, label1, text, label2, text, milestone and text' do
        input_filtered_search("bug author:@#{user.username} assignee:@#{user.username} report label:~#{bug_label.title} label:~#{caps_sensitive_label.title} milestone:%#{milestone.title} foo")

        expect_issues_list_count(1)
        expect_filtered_search_input('bug report foo')
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

        sort_toggle = find('.filtered-search-wrapper .dropdown-toggle')
        sort_toggle.click

        find('.filtered-search-wrapper .dropdown-menu li a', text: 'Oldest updated').click
        wait_for_requests

        expect(find('.issues-list .issue:first-of-type .issue-title-text a')).to have_content(old_issue.title)
      end
    end
  end

  describe 'retains filter when switching issue states' do
    before do
      input_filtered_search('bug')

      # This ensures that the search is performed
      expect_issues_list_count(4, 1)
    end

    it 'open state' do
      find('.issues-state-filters [data-state="closed"]').click
      wait_for_requests

      find('.issues-state-filters [data-state="opened"]').click
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 4)
    end

    it 'closed state' do
      find('.issues-state-filters [data-state="closed"]').click
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 1)
      expect(find('.issues-list .issue:first-of-type .issue-title-text a')).to have_content(closed_issue.title)
    end

    it 'all state' do
      find('.issues-state-filters [data-state="all"]').click
      wait_for_requests

      expect(page).to have_selector('.issues-list .issue', count: 5)
    end
  end

  describe 'RSS feeds' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }

    before do
      group.add_developer(user)
    end

    it 'updates atom feed link for project issues' do
      visit project_issues_path(project, milestone_title: milestone.title, assignee_id: user.id)
      link = find_link('Subscribe')
      params = CGI.parse(URI.parse(link[:href]).query)
      auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
      auto_discovery_params = CGI.parse(URI.parse(auto_discovery_link[:href]).query)

      expect(params).to include('rss_token' => [user.rss_token])
      expect(params).to include('milestone_title' => [milestone.title])
      expect(params).to include('assignee_id' => [user.id.to_s])
      expect(auto_discovery_params).to include('rss_token' => [user.rss_token])
      expect(auto_discovery_params).to include('milestone_title' => [milestone.title])
      expect(auto_discovery_params).to include('assignee_id' => [user.id.to_s])
    end

    it 'updates atom feed link for group issues' do
      visit issues_group_path(group, milestone_title: milestone.title, assignee_id: user.id)
      link = find('.breadcrumbs a', text: 'Subscribe')
      params = CGI.parse(URI.parse(link[:href]).query)
      auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
      auto_discovery_params = CGI.parse(URI.parse(auto_discovery_link[:href]).query)

      expect(params).to include('rss_token' => [user.rss_token])
      expect(params).to include('milestone_title' => [milestone.title])
      expect(params).to include('assignee_id' => [user.id.to_s])
      expect(auto_discovery_params).to include('rss_token' => [user.rss_token])
      expect(auto_discovery_params).to include('milestone_title' => [milestone.title])
      expect(auto_discovery_params).to include('assignee_id' => [user.id.to_s])
    end
  end

  context 'URL has a trailing slash' do
    before do
      visit "#{project_issues_path(project)}/"
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
