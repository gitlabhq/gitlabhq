require 'rails_helper'

describe 'issuable list', feature: true do
  let(:project) { create(:empty_project) }
  let(:user)    { create(:user) }

  issuable_types = [:issue, :merge_request]

  before do
    project.add_user(user, :developer)
    login_as(user)
    issuable_types.each { |type| create_issuables(type) }
  end

  issuable_types.each do |issuable_type|
    it "avoids N+1 database queries for #{issuable_type.to_s.humanize.pluralize}" do
      control_count = ActiveRecord::QueryRecorder.new { visit_issuable_list(issuable_type) }.count

      create_issuables(issuable_type)

      expect { visit_issuable_list(issuable_type) }.not_to exceed_query_limit(control_count)
    end

    it "counts upvotes, downvotes and notes count for each #{issuable_type.to_s.humanize}" do
      visit_issuable_list(issuable_type)

      expect(first('.fa-thumbs-up').find(:xpath, '..')).to have_content(1)
      expect(first('.fa-thumbs-down').find(:xpath, '..')).to have_content(1)
      expect(first('.fa-comments').find(:xpath, '..')).to have_content(2)
    end
  end

  it "counts merge requests closing issues icons for each issue" do
    visit_issuable_list(:issue)

    expect(page).to have_selector('.icon-merge-request-unmerged', count: 1)
    expect(first('.icon-merge-request-unmerged').find(:xpath, '..')).to have_content(1)
  end

  def visit_issuable_list(issuable_type)
    if issuable_type == :issue
      visit namespace_project_issues_path(project.namespace, project)
    else
      visit namespace_project_merge_requests_path(project.namespace, project)
    end
  end

  def create_issuables(issuable_type)
    3.times do
      issuable =
        if issuable_type == :issue
          create(:issue, project: project, author: user)
        else
          create(:merge_request, title: FFaker::Lorem.sentence, source_project: project, source_branch: FFaker::Name.name)
        end

      2.times do
        create(:note_on_issue, noteable: issuable, project: project, note: 'Test note')
      end

      create(:award_emoji, :downvote, awardable: issuable)
      create(:award_emoji, :upvote, awardable: issuable)
    end

    if issuable_type == :issue
      issue = Issue.reorder(:iid).first
      merge_request = create(:merge_request,
                              title: FFaker::Lorem.sentence,
                              source_project: project,
                              source_branch: FFaker::Name.name)

      MergeRequestsClosingIssues.create!(issue: issue, merge_request: merge_request)
    end
  end
end
