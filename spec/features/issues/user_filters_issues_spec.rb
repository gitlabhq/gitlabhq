# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User filters issues', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, :public) }

  before do
    %w[foobar barbaz].each do |title|
      create(:issue,
             author: user,
             assignees: [user],
             project: project,
             title: title)
    end

    @issue = Issue.find_by(title: 'foobar')
    @issue.milestone = create(:milestone, project: project)
    @issue.assignees = []
    @issue.save!
  end

  let(:issue) { @issue }

  it 'allows filtering by issues with no specified assignee' do
    visit project_issues_path(project, assignee_id: IssuableFinder::Params::FILTER_NONE)

    expect(page).to have_content 'foobar'
    expect(page).not_to have_content 'barbaz'
  end

  it 'allows filtering by a specified assignee' do
    visit project_issues_path(project, assignee_id: user.id)

    expect(page).not_to have_content 'foobar'
    expect(page).to have_content 'barbaz'
  end
end
