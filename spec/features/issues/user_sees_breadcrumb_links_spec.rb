# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New issue breadcrumb' do
  let_it_be(:project, reload: true) { create(:project) }

  let(:user) { project.creator }

  before do
    stub_feature_flags(vue_issuables_list: false)

    sign_in(user)
    visit(new_project_issue_path(project))
  end

  it 'displays link to project issues and new issue' do
    page.within '.breadcrumbs' do
      expect(find_link('Issues')[:href]).to end_with(project_issues_path(project))
      expect(find_link('New')[:href]).to end_with(new_project_issue_path(project))
    end
  end

  it 'links to current issue in breadcrubs' do
    issue = create(:issue, project: project)

    visit project_issue_path(project, issue)

    expect(find('.breadcrumbs-sub-title a')[:href]).to end_with(issue_path(issue))
  end

  it 'excludes award_emoji from comment count' do
    issue = create(:issue, author: user, assignees: [user], project: project, title: 'foobar')
    create(:award_emoji, awardable: issue)

    visit project_issues_path(project, assignee_id: user.id)

    expect(page).to have_content 'foobar'
    expect(page.all('.no-comments').first.text).to eq "0"
  end
end
