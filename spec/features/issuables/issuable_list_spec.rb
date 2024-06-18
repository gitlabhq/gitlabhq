# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issuable list', :js, feature_category: :team_planning do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  issuable_types = [:issue, :merge_request]

  before do
    project.add_member(user, :developer)
    sign_in(user)
    issuable_types.each { |type| create_issuables(type) }
  end

  issuable_types.each do |issuable_type|
    it "avoids N+1 database queries for #{issuable_type.to_s.humanize.pluralize}", quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/231426' } do
      control = ActiveRecord::QueryRecorder.new { visit_issuable_list(issuable_type) }

      create_issuables(issuable_type)

      expect { visit_issuable_list(issuable_type) }.not_to exceed_query_limit(control)
    end

    it "counts upvotes, downvotes and notes count for each #{issuable_type.to_s.humanize}", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446199' do
      visit_issuable_list(issuable_type)

      expect(first('[data-testid="issuable-upvotes"]')).to have_content(1)
      expect(first('[data-testid="issuable-downvotes"]')).to have_content(1)
      expect(first('[data-testid="issuable-comments"]')).to have_content(2)
    end

    it 'sorts labels alphabetically', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446203' do
      label1 = create(:label, project: project, title: 'a')
      label2 = create(:label, project: project, title: 'z')
      label3 = create(:label, project: project, title: 'x')
      label4 = create(:label, project: project, title: 'b')
      issuable = create_issuable(issuable_type)
      issuable.labels << [label1, label2, label3, label4]

      visit_issuable_list(issuable_type)

      expect(all('.gl-label-text')[0].text).to have_content('a')
      expect(all('.gl-label-text')[1].text).to have_content('b')
      expect(all('.gl-label-text')[2].text).to have_content('x')
      expect(all('.gl-label-text')[3].text).to have_content('z')
    end
  end

  it 'displays a warning if counting the number of issues times out', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/393344' do
    allow_any_instance_of(IssuesFinder).to receive(:count_by_state).and_raise(ActiveRecord::QueryCanceled)

    visit_issuable_list(:issue)

    expect(page).to have_text('Open Closed All')
  end

  it "counts merge requests closing issues icons for each issue" do
    visit_issuable_list(:issue)

    expect(page).to have_selector('[data-testid="merge-requests"]', count: 1)
    expect(first('[data-testid="merge-requests"]').find(:xpath, '..')).to have_content(1)
  end

  def visit_issuable_list(issuable_type)
    if issuable_type == :issue
      visit project_issues_path(project)
    else
      visit project_merge_requests_path(project)
    end
  end

  def create_issuable(issuable_type)
    if issuable_type == :issue
      create(:issue, project: project)
    else
      create(:merge_request, source_project: project)
    end
  end

  def create_issuables(issuable_type)
    3.times do |n|
      issuable =
        if issuable_type == :issue
          create(:issue, project: project, author: user)
        else
          create(:merge_request, source_project: project, source_branch: generate(:branch))
          source_branch = FFaker::Lorem.characters(8)
          pipeline = create(:ci_empty_pipeline, project: project, ref: source_branch, status: %w[running failed success].sample, sha: 'any')
          create(:merge_request, title: FFaker::Lorem.sentence, source_project: project, source_branch: source_branch, head_pipeline: pipeline)
        end

      create_list(:note_on_issue, 2, noteable: issuable, project: project)

      create(:award_emoji, :downvote, awardable: issuable)
      create(:award_emoji, :upvote, awardable: issuable)
    end

    if issuable_type == :issue
      issue = Issue.reorder(:iid).first
      merge_request = create(:merge_request, source_project: project, source_branch: generate(:branch))

      create(:merge_requests_closing_issues, issue: issue, merge_request: merge_request)
    end
  end
end
