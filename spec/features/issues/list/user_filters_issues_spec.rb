# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User filters issues', :js, feature_category: :team_planning do
  before do
    # TODO: When removing the feature flag,
    # we won't need these tests for issues, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
    stub_feature_flags(work_item_view_for_issues: true)

    %w[foobar barbaz].each do |title|
      create(
        :issue,
        author: user,
        assignees: [user],
        project: project,
        title: title
      )
    end

    @issue = Issue.find_by(title: 'foobar')
    @issue.milestone = create(:milestone, project: project)
    @issue.assignees = []
    @issue.save!
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let(:issue) { @issue }

  it 'allows filtering by issues with no specified assignee' do
    visit project_issues_path(project, assignee_id: IssuableFinder::Params::FILTER_NONE.capitalize)

    expect(page).to have_content 'foobar'
    expect(page).not_to have_content 'barbaz'
  end
end
