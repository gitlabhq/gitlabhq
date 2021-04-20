# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User views milestone" do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:milestone) { create(:milestone, project: project, description: '**Lorem** _ipsum_ dolor sit [amet](https://example.com)') }
  let_it_be(:labels) { create_list(:label, 2, project: project) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
  end

  context 'page description' do
    before do
      visit(project_milestone_path(project, milestone))
    end

    it_behaves_like 'page meta description', 'Lorem ipsum dolor sit amet'
  end

  it "avoids N+1 database queries" do
    issue_params = { project: project, assignees: [user], author: user, milestone: milestone, labels: labels }.freeze

    create(:labeled_issue, issue_params)

    control = ActiveRecord::QueryRecorder.new { visit_milestone }

    create(:labeled_issue, issue_params)

    expect { visit_milestone }.not_to exceed_query_limit(control)
  end

  context 'issues list', :js do
    before_all do
      2.times do
        create(:issue, milestone: milestone, project: project)
        create(:issue, milestone: milestone, project: project, assignees: [user])
        create(:issue, milestone: milestone, project: project, state: :closed)
      end
    end

    context 'for a project milestone' do
      it 'does not show the project name' do
        visit(project_milestone_path(project, milestone))

        wait_for_requests

        expect(page.find('#tab-issues')).not_to have_text(project.name)
      end
    end

    context 'for a group milestone' do
      let(:group_milestone) { create(:milestone, group: group) }

      it 'shows the project name' do
        create(:issue, project: project, milestone: group_milestone)

        visit(group_milestone_path(group, group_milestone))

        expect(page.find('#tab-issues')).to have_text(project.name)
      end
    end

    context 'when issues on milestone are over DISPLAY_ISSUES_LIMIT' do
      it "limits issues to display and shows warning" do
        stub_const('Milestoneish::DISPLAY_ISSUES_LIMIT', 3)

        visit(project_milestone_path(project, milestone))

        expect(page).to have_selector('.issuable-row', count: 3)
        expect(page).to have_selector('#milestone-issue-count-warning', text: 'Showing 3 of 6 issues. View all issues')
        expect(page).to have_link('View all issues', href: project_issues_path(project, { milestone_title: milestone.title }))
      end
    end

    context 'when issues on milestone are below DISPLAY_ISSUES_LIMIT' do
      it 'does not display warning' do
        visit(project_milestone_path(project, milestone))

        expect(page).not_to have_selector('#milestone-issue-count-warning', text: 'Showing 3 of 6 issues. View all issues')
        expect(page).to have_selector('.issuable-row', count: 6)
      end
    end
  end

  context 'merge requests list', :js do
    context 'for a project milestone' do
      it 'does not show the project name' do
        create(:merge_request, source_project: project, milestone: milestone)

        visit(project_milestone_path(project, milestone))

        within('.js-milestone-tabs') do
          click_link('Merge requests')
        end

        wait_for_requests

        expect(page.find('#tab-merge-requests')).not_to have_text(project.name)
      end
    end

    context 'for a group milestone' do
      let(:group_milestone) { create(:milestone, group: group) }

      it 'shows the project name' do
        create(:merge_request, source_project: project, milestone: group_milestone)

        visit(group_milestone_path(group, group_milestone))

        within('.js-milestone-tabs') do
          click_link('Merge requests')
        end

        expect(page.find('#tab-merge-requests')).to have_text(project.name)
      end
    end
  end

  private

  def visit_milestone
    visit(project_milestone_path(project, milestone))
  end
end
