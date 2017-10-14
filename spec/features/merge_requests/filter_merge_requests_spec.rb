require 'rails_helper'

describe 'Filter merge requests' do
  include FilteredSearchHelpers
  include MergeRequestHelpers

  let!(:project)   { create(:project, :repository) }
  let!(:group)     { create(:group) }
  let!(:user)      { create(:user) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:wontfix)   { create(:label, project: project, title: "Won't fix") }

  before do
    project.add_master(user)
    group.add_developer(user)
    sign_in(user)
    create(:merge_request, source_project: project, target_project: project)

    visit project_merge_requests_path(project)
  end

  describe 'for assignee from mr#index' do
    let(:search_query) { "assignee:@#{user.username}" }

    def expect_assignee_visual_tokens
      expect_tokens([{ name: 'assignee', value: "@#{user.username}" }])
      expect_filtered_search_input_empty
    end

    before do
      input_filtered_search(search_query)

      expect_mr_list_count(0)
    end

    context 'assignee', js: true do
      it 'updates to current user' do
        expect_assignee_visual_tokens()
      end

      it 'does not change when closed link is clicked' do
        find('.issues-state-filters [data-state="closed"]').click

        expect_assignee_visual_tokens()
      end

      it 'does not change when all link is clicked' do
        find('.issues-state-filters [data-state="all"]').click

        expect_assignee_visual_tokens()
      end
    end
  end

  describe 'for milestone from mr#index' do
    let(:search_query) { "milestone:%\"#{milestone.title}\"" }

    def expect_milestone_visual_tokens
      expect_tokens([{ name: 'milestone', value: "%\"#{milestone.title}\"" }])
      expect_filtered_search_input_empty
    end

    before do
      input_filtered_search(search_query)

      expect_mr_list_count(0)
    end

    context 'milestone', js: true do
      it 'updates to current milestone' do
        expect_milestone_visual_tokens()
      end

      it 'does not change when closed link is clicked' do
        find('.issues-state-filters [data-state="closed"]').click

        expect_milestone_visual_tokens()
      end

      it 'does not change when all link is clicked' do
        find('.issues-state-filters [data-state="all"]').click

        expect_milestone_visual_tokens()
      end
    end
  end

  describe 'for label from mr#index', js: true do
    it 'filters by no label' do
      input_filtered_search('label:none')

      expect_mr_list_count(1)
      expect_tokens([{ name: 'label', value: 'none' }])
      expect_filtered_search_input_empty
    end

    it 'filters by a label' do
      input_filtered_search("label:~#{label.title}")

      expect_mr_list_count(0)
      expect_tokens([{ name: 'label', value: "~#{label.title}" }])
      expect_filtered_search_input_empty
    end

    it "filters by `won't fix` and another label" do
      input_filtered_search("label:~\"#{wontfix.title}\" label:~#{label.title}")

      expect_mr_list_count(0)
      expect_tokens([
        { name: 'label', value: "~\"#{wontfix.title}\"" },
        { name: 'label', value: "~#{label.title}" }
      ])
      expect_filtered_search_input_empty
    end

    it "filters by `won't fix` label followed by another label after page load" do
      input_filtered_search("label:~\"#{wontfix.title}\"")

      expect_mr_list_count(0)
      expect_tokens([{ name: 'label', value: "~\"#{wontfix.title}\"" }])
      expect_filtered_search_input_empty

      input_filtered_search_keys("label:~#{label.title}")

      expect_mr_list_count(0)
      expect_tokens([
        { name: 'label', value: "~\"#{wontfix.title}\"" },
        { name: 'label', value: "~#{label.title}" }
      ])
      expect_filtered_search_input_empty
    end
  end

  describe 'for assignee and label from mr#index' do
    let(:search_query) { "assignee:@#{user.username} label:~#{label.title}" }

    before do
      input_filtered_search(search_query)

      expect_mr_list_count(0)
    end

    context 'assignee and label', js: true do
      def expect_assignee_label_visual_tokens
        expect_tokens([
          { name: 'assignee', value: "@#{user.username}" },
          { name: 'label', value: "~#{label.title}" }
        ])
        expect_filtered_search_input_empty
      end

      it 'updates to current assignee and label' do
        expect_assignee_label_visual_tokens()
      end

      it 'does not change when closed link is clicked' do
        find('.issues-state-filters [data-state="closed"]').click

        expect_assignee_label_visual_tokens()
      end

      it 'does not change when all link is clicked' do
        find('.issues-state-filters [data-state="all"]').click

        expect_assignee_label_visual_tokens()
      end
    end
  end

  describe 'filter merge requests by text' do
    before do
      create(:merge_request, title: "Bug", source_project: project, target_project: project, source_branch: "wip")

      bug_label = create(:label, project: project, title: 'bug')
      milestone = create(:milestone, title: "8", project: project)

      mr = create(:merge_request,
        title: "Bug 2",
        source_project: project,
        target_project: project,
        source_branch: "fix",
        milestone: milestone,
        author: user,
        assignee: user)
      mr.labels << bug_label

      visit project_merge_requests_path(project)
    end

    context 'only text', js: true do
      it 'filters merge requests by searched text' do
        input_filtered_search('bug')

        expect_mr_list_count(2)
      end

      it 'does not show any merge requests' do
        input_filtered_search('testing')

        page.within '.mr-list' do
          expect(page).not_to have_selector('.merge-request')
        end
      end
    end

    context 'filters and searches', js: true do
      it 'filters by text and label' do
        input_filtered_search('Bug')

        expect_mr_list_count(2)
        expect_filtered_search_input('Bug')

        input_filtered_search_keys(' label:~bug')

        expect_mr_list_count(1)
        expect_tokens([{ name: 'label', value: '~bug' }])
        expect_filtered_search_input('Bug')
      end

      it 'filters by text and milestone' do
        input_filtered_search('Bug')

        expect_mr_list_count(2)
        expect_filtered_search_input('Bug')

        input_filtered_search_keys(' milestone:%8')

        expect_mr_list_count(1)
        expect_tokens([{ name: 'milestone', value: '%8' }])
        expect_filtered_search_input('Bug')
      end

      it 'filters by text and assignee' do
        input_filtered_search('Bug')

        expect_mr_list_count(2)
        expect_filtered_search_input('Bug')

        input_filtered_search_keys(" assignee:@#{user.username}")

        expect_mr_list_count(1)
        expect_tokens([{ name: 'assignee', value: "@#{user.username}" }])
        expect_filtered_search_input('Bug')
      end

      it 'filters by text and author' do
        input_filtered_search('Bug')

        expect_mr_list_count(2)
        expect_filtered_search_input('Bug')

        input_filtered_search_keys(" author:@#{user.username}")

        expect_mr_list_count(1)
        expect_tokens([{ name: 'author', value: "@#{user.username}" }])
        expect_filtered_search_input('Bug')
      end
    end
  end

  describe 'filter merge requests and sort', :js do
    before do
      bug_label = create(:label, project: project, title: 'bug')

      mr1 = create(:merge_request, title: "Frontend", source_project: project, target_project: project, source_branch: "wip")
      mr2 = create(:merge_request, title: "Bug 2", source_project: project, target_project: project, source_branch: "fix")

      mr1.labels << bug_label
      mr2.labels << bug_label

      visit project_merge_requests_path(project)
    end

    it 'is able to filter and sort merge requests' do
      input_filtered_search('label:~bug')

      expect_mr_list_count(2)

      click_button 'Last created'
      page.within '.dropdown-menu-sort' do
        click_link 'Oldest created'
      end
      wait_for_requests

      page.within '.mr-list' do
        expect(page).to have_content('Frontend')
      end
    end
  end

  describe 'filter by assignee id', js: true do
    it 'filter by current user' do
      visit project_merge_requests_path(project, assignee_id: user.id)

      expect_tokens([{ name: 'assignee', value: "@#{user.username}" }])
      expect_filtered_search_input_empty
    end

    it 'filter by new user' do
      new_user = create(:user)
      project.add_developer(new_user)

      visit project_merge_requests_path(project, assignee_id: new_user.id)

      expect_tokens([{ name: 'assignee', value: "@#{new_user.username}" }])
      expect_filtered_search_input_empty
    end
  end

  describe 'filter by author id', js: true do
    it 'filter by current user' do
      visit project_merge_requests_path(project, author_id: user.id)

      expect_tokens([{ name: 'author', value: "@#{user.username}" }])
      expect_filtered_search_input_empty
    end

    it 'filter by new user' do
      new_user = create(:user)
      project.add_developer(new_user)

      visit project_merge_requests_path(project, author_id: new_user.id)

      expect_tokens([{ name: 'author', value: "@#{new_user.username}" }])
      expect_filtered_search_input_empty
    end
  end
end
