require 'rails_helper'

describe 'Filter issues', feature: true do
  include WaitForAjax

  let!(:group)     { create(:group) }
  let!(:project)   { create(:project) }
  let!(:user)      { create(:user)}
  let!(:user)      { create(:user) }
  let!(:user2)      { create(:user) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:wontfix)   { create(:label, project: project, title: "Won't fix") }

  let!(:bug_label) { create(:label, project: project, title: 'bug') }
  let!(:caps_sensitive_label) { create(:label, project: project, title: 'CAPS_sensitive') }
  let!(:milestone) { create(:milestone, title: "8", project: project) }

  def input_filtered_search(search_term)
    filtered_search = find('.filtered-search')
    filtered_search.set(search_term)
    filtered_search.send_keys(:enter)
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

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'filter issues by author' do
    context 'only author', js: true do
      it 'filters issues by searched author' do
        input_filtered_search("author:#{user.username}")
        expect_issues_list_count(5)
      end

      it 'filters issues by invalid author' do
        # YOLO
      end

      it 'filters issues by multiple authors' do
        # YOLO
      end
    end

    context 'author with other filters', js: true do
      it 'filters issues by searched author and text' do
        input_filtered_search("author:#{user.username} issue")
        expect_issues_list_count(3)
      end

      it 'filters issues by searched author, assignee and text' do
        input_filtered_search("author:#{user.username} assignee:#{user.username} issue")
        expect_issues_list_count(3)
      end

      it 'filters issues by searched author, assignee, label, and text' do
        input_filtered_search("author:#{user.username} assignee:#{user.username} label:#{caps_sensitive_label.title} issue")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched author, assignee, label, milestone and text' do
        input_filtered_search("author:#{user.username} assignee:#{user.username} label:#{caps_sensitive_label.title} milestone:#{milestone.title} issue")
        expect_issues_list_count(1)
      end
    end

    context 'sorting', js: true do
      # TODO
    end
  end

  describe 'filter issues by assignee' do
    context 'only assignee', js: true do
      it 'filters issues by searched assignee' do
        input_filtered_search("assignee:#{user.username}")
        expect_issues_list_count(5)
      end

      it 'filters issues by no assignee' do
        # TODO
      end

      it 'filters issues by invalid assignee' do
        # YOLO
      end

      it 'filters issues by multiple assignees' do
        # YOLO
      end
    end

    context 'assignee with other filters', js: true do
      it 'filters issues by searched assignee and text' do
        input_filtered_search("assignee:#{user.username} searchTerm")
        expect_issues_list_count(2)
      end

      it 'filters issues by searched assignee, author and text' do
        input_filtered_search("assignee:#{user.username} author:#{user.username} searchTerm")
        expect_issues_list_count(2)
      end

      it 'filters issues by searched assignee, author, label, text' do
        input_filtered_search("assignee:#{user.username} author:#{user.username} label:#{caps_sensitive_label.title} searchTerm")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched assignee, author, label, milestone and text' do
        input_filtered_search("assignee:#{user.username} author:#{user.username} label:#{caps_sensitive_label.title} milestone:#{milestone.title} searchTerm")
        expect_issues_list_count(1)
      end
    end

    context 'sorting', js: true do
      # TODO
    end
  end

  describe 'filter issues by label' do
    context 'only label', js: true do
      it 'filters issues by searched label' do
        input_filtered_search("label:#{bug_label.title}")
        expect_issues_list_count(2)
      end

      it 'filters issues by no label' do
        # TODO
      end

      it 'filters issues by invalid label' do
        # YOLO
      end

      it 'filters issues by multiple labels' do
        input_filtered_search("label:#{bug_label.title} label:#{caps_sensitive_label.title}")
        expect_issues_list_count(1)
      end
    end

    context 'label with other filters', js: true do
      it 'filters issues by searched label and text' do
        input_filtered_search("label:#{caps_sensitive_label.title} bug")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched label, author and text' do
        input_filtered_search("label:#{caps_sensitive_label.title} author:#{user.username} bug")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched label, author, assignee and text' do
        input_filtered_search("label:#{caps_sensitive_label.title} author:#{user.username} assignee:#{user.username} bug")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched label, author, assignee, milestone and text' do
        input_filtered_search("label:#{caps_sensitive_label.title} author:#{user.username} assignee:#{user.username} milestone:#{milestone.title} bug")
        expect_issues_list_count(1)
      end
    end

    context 'multiple labels with other filters', js: true do
      it 'filters issues by searched label, label2, and text' do
        input_filtered_search("label:#{bug_label.title} label:#{caps_sensitive_label.title} bug")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched label, label2, author and text' do
        input_filtered_search("label:#{bug_label.title} label:#{caps_sensitive_label.title} author:#{user.username} bug")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched label, label2, author, assignee and text' do
        input_filtered_search("label:#{bug_label.title} label:#{caps_sensitive_label.title} author:#{user.username} assignee:#{user.username} bug")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched label, label2, author, assignee, milestone and text' do
        input_filtered_search("label:#{bug_label.title} label:#{caps_sensitive_label.title} author:#{user.username} assignee:#{user.username} milestone:#{milestone.title} bug")
        expect_issues_list_count(1)
      end
    end

    it "selects and unselects `won't fix`" do
      find('.dropdown-menu-labels a', text: wontfix.title).click
      find('.dropdown-menu-labels a', text: wontfix.title).click

      find('.dropdown-menu-close-icon').click
      expect(page).not_to have_css('.filtered-labels')
    context 'sorting', js: true do
      # TODO
    end
  end

  describe 'filter issues by milestone' do
    context 'only milestone', js: true do
      it 'filters issues by searched milestone' do
        input_filtered_search("milestone:#{milestone.title}")
        expect_issues_list_count(5)
      end

      it 'filters issues by no milestone' do
        # TODO
      end

      it 'filters issues by upcoming milestones' do
        # TODO
      end

      it 'filters issues by invalid milestones' do
        # YOLO
      end

      it 'filters issues by multiple milestones' do
        # YOLO
      end
    end

    context 'milestone with other filters', js: true do
      it 'filters issues by searched milestone and text' do
      end

      it 'filters issues by searched milestone, author and text' do
      end

      it 'filters issues by searched milestone, author, assignee and text' do
      end

      it 'filters issues by searched milestone, author, assignee, label and text' do
      end
    end

    context 'sorting', js: true do
      # TODO
    end
  end

  describe 'filter issues by text' do
    context 'only text', js: true do
      it 'filters issues by searched text' do
        input_filtered_search('Bug')
        expect_issues_list_count(4)
      end

      it 'filters issues by multiple searched text' do
        input_filtered_search('Bug report')
        expect_issues_list_count(3)
      end

      it 'filters issues by case insensitive searched text' do
        input_filtered_search('bug report')
        expect_issues_list_count(3)
      end

      it 'filters issues by searched text containing single quotes' do
        input_filtered_search('\'single quotes\'')
        expect_issues_list_count(1)
      end

      it 'filters issues by searched text containing double quotes' do
        input_filtered_search('"double quotes"')
        expect_issues_list_count(1)
      end

      it 'filters issues by searched text containing special characters' do
        input_filtered_search('!@#{$%^&*()-+')
        expect_issues_list_count(1)
      end

      it 'does not show any issues' do
        input_filtered_search('testing')
        expect_no_issues_list()
      end
    end

    context 'searched text with other filters', js: true do
      it 'filters issues by searched text and author' do
        input_filtered_search("bug author:#{user.username}")
        expect_issues_list_count(2)
      end

      it 'filters issues by searched text, author and more text' do
        input_filtered_search("bug author:#{user.username} report")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched text, author and assignee' do
        input_filtered_search("bug author:#{user.username} assignee:#{user.username}")
        expect_issues_list_count(2)
      end

      it 'filters issues by searched text, author, more text and assignee' do
        input_filtered_search("bug author:#{user.username} report assignee:#{user.username}")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched text, author, more text, assignee and even more text' do
        input_filtered_search("bug author:#{user.username} report assignee:#{user.username} with")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched text, author, assignee and label' do
        input_filtered_search("bug author:#{user.username} assignee:#{user.username} label:#{bug_label.title}")
        expect_issues_list_count(2)
      end

      it 'filters issues by searched text, author, text, assignee, text, label and text' do
        input_filtered_search("bug author:#{user.username} report assignee:#{user.username} with label:#{bug_label.title} everything")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched text, author, assignee, label and milestone' do
        input_filtered_search("bug author:#{user.username} assignee:#{user.username} label:#{bug_label.title} milestone:#{milestone.title}")
        expect_issues_list_count(2)
      end

      it 'filters issues by searched text, author, text, assignee, text, label, text, milestone and text' do
        input_filtered_search("bug author:#{user.username} report assignee:#{user.username} with label:#{bug_label.title} everything milestone:#{milestone.title} you")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched text, author, assignee, multiple labels and milestone' do
        input_filtered_search("bug author:#{user.username} assignee:#{user.username} label:#{bug_label.title} label:#{caps_sensitive_label.title} milestone:#{milestone.title}")
        expect_issues_list_count(1)
      end

      it 'filters issues by searched text, author, text, assignee, text, label1, text, label2, text, milestone and text' do
        input_filtered_search("bug author:#{user.username} report assignee:#{user.username} with label:#{bug_label.title} everything label:#{caps_sensitive_label.title} you milestone:#{milestone.title} thought")
        expect_issues_list_count(1)
      end
    end

    context 'sorting', js: true do
      # TODO
    end
  end

  it 'updates atom feed link for project issues' do
    visit namespace_project_issues_path(project.namespace, project, milestone_title: '', assignee_id: user.id)
    link = find('.nav-controls a', text: 'Subscribe')
    params = CGI::parse(URI.parse(link[:href]).query)
    auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
    auto_discovery_params = CGI::parse(URI.parse(auto_discovery_link[:href]).query)
    expect(params).to include('private_token' => [user.private_token])
    expect(params).to include('milestone_title' => [''])
    expect(params).to include('assignee_id' => [user.id.to_s])
    expect(auto_discovery_params).to include('private_token' => [user.private_token])
    expect(auto_discovery_params).to include('milestone_title' => [''])
    expect(auto_discovery_params).to include('assignee_id' => [user.id.to_s])
  end

  it 'updates atom feed link for group issues' do
    visit issues_group_path(group, milestone_title: '', assignee_id: user.id)
    link = find('.nav-controls a', text: 'Subscribe')
    params = CGI::parse(URI.parse(link[:href]).query)
    auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
    auto_discovery_params = CGI::parse(URI.parse(auto_discovery_link[:href]).query)
    expect(params).to include('private_token' => [user.private_token])
    expect(params).to include('milestone_title' => [''])
    expect(params).to include('assignee_id' => [user.id.to_s])
    expect(auto_discovery_params).to include('private_token' => [user.private_token])
    expect(auto_discovery_params).to include('milestone_title' => [''])
    expect(auto_discovery_params).to include('assignee_id' => [user.id.to_s])
  end
end
