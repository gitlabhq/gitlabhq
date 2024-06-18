# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits issue boards', :js, feature_category: :portfolio_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create_default(:group, :public) }
  let_it_be(:project) { create_default(:project, :public, group: group) }

  # TODO use 'let' when rspec-parameterized supports it.
  # https://gitlab.com/gitlab-org/gitlab/-/issues/329746
  label_name1 = 'foobar'
  label_name2 = 'in dev'
  assignee_username = 'root'
  issue_with_label1 = "issue with label1"
  issue_with_label2 = "issue with label2"
  issue_with_assignee = "issue with assignee"
  issue_with_milestone = "issue with milestone"
  issue_with_all_filters = "issue with all filters"

  let_it_be(:label1) { create(:group_label, group: group, name: label_name1) }
  let_it_be(:label2) { create(:group_label, group: group, name: label_name2) }
  let_it_be(:assignee) { create_default(:group_member, :maintainer, user: create(:user, username: assignee_username), group: group).user }
  let_it_be(:milestone) { create_default(:milestone, project: project, start_date: Date.today - 1, due_date: 7.days.from_now) }

  before_all do
    create_default(:issue, project: project, title: issue_with_label1, labels: [label1])
    create_default(:issue, project: project, title: issue_with_label2, labels: [label2])
    create_default(:issue, project: project, title: issue_with_assignee, assignees: [assignee])
    create_default(:issue, project: project, title: issue_with_milestone, milestone: milestone)
    create_default(:issue, project: project, title: issue_with_all_filters, labels: [label1, label2], assignees: [assignee], milestone: milestone)
  end

  shared_examples "visiting board path with search params" do
    where(:params, :expected_issues) do
      { "label_name" => [label_name1] }              | [issue_with_label1, issue_with_all_filters]
      { "label_name" => [label_name2] }              | [issue_with_label2, issue_with_all_filters]
      { "label_name" => [label_name1, label_name2] } | [issue_with_all_filters]
      { "assignee_username" => assignee_username }   | [issue_with_assignee, issue_with_all_filters]
      { "milestone_title" => '#started' }            | [issue_with_milestone, issue_with_all_filters]
      { "label_name" => [label_name1, label_name2], "assignee_username" => assignee_username } | [issue_with_all_filters]
    end

    with_them do
      before do
        visit board_path

        wait_for_requests
      end

      it 'displays all issues satisfiying filter params and correctly sets url params' do
        expect(page).to have_current_path(board_path)

        page.assert_selector('[data-testid="board-card"]', count: expected_issues.length)
        expected_issues.each { |issue_title| expect(page).to have_link issue_title }
      end
    end
  end

  context "project boards" do
    let_it_be(:board) { create_default(:board, project: project) }

    let(:board_path) { project_boards_path(project, params) }

    include_examples "visiting board path with search params"
  end

  context "group boards" do
    let_it_be(:board) { create_default(:board, group: group) }

    let(:board_path) { group_boards_path(group, params) }

    include_examples 'visiting board path with search params'
  end
end
