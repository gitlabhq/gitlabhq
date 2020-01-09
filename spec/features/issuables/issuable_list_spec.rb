# frozen_string_literal: true

require 'spec_helper'

describe 'issuable list' do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  issuable_types = [:issue, :merge_request]

  before do
    project.add_user(user, :developer)
    sign_in(user)
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

    it 'sorts labels alphabetically' do
      label1 = create(:label, project: project, title: 'a')
      label2 = create(:label, project: project, title: 'z')
      label3 = create(:label, project: project, title: 'X')
      label4 = create(:label, project: project, title: 'B')
      issuable = create_issuable(issuable_type)
      issuable.labels << [label1, label2, label3, label4]

      visit_issuable_list(issuable_type)

      expect(all('.label-link')[0].text).to have_content('B')
      expect(all('.label-link')[1].text).to have_content('X')
      expect(all('.label-link')[2].text).to have_content('a')
      expect(all('.label-link')[3].text).to have_content('z')
    end
  end

  it "counts merge requests closing issues icons for each issue" do
    visit_issuable_list(:issue)

    expect(page).to have_selector('.icon-merge-request-unmerged', count: 1)
    expect(first('.icon-merge-request-unmerged').find(:xpath, '..')).to have_content(1)
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
          pipeline = create(:ci_empty_pipeline, project: project, ref: source_branch, status: %w(running failed success).sample, sha: 'any')
          create(:merge_request, title: FFaker::Lorem.sentence, source_project: project, source_branch: source_branch, head_pipeline: pipeline)
        end

      create_list(:note_on_issue, 2, noteable: issuable, project: project)

      create(:award_emoji, :downvote, awardable: issuable)
      create(:award_emoji, :upvote, awardable: issuable)
    end

    if issuable_type == :issue
      issue = Issue.reorder(:iid).first
      merge_request = create(:merge_request,
                              source_project: project,
                              source_branch: generate(:branch))

      create(:merge_requests_closing_issues, issue: issue, merge_request: merge_request)
    end
  end
end
