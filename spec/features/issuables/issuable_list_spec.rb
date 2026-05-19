# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issuable list', :js, feature_category: :portfolio_management do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }

  issuable_types = [:issue, :merge_request]

  before do
    project.add_member(user, :developer)
    create(:callout, user: user, feature_name: :work_items_onboarding_modal)
    sign_in(user)
    issuable_types.each { |type| create_issuables(type) }
  end

  issuable_types.each do |issuable_type|
    it "counts upvotes, downvotes for each #{issuable_type.to_s.humanize}" do
      visit_issuable_list(issuable_type)

      expect(first('[data-testid="issuable-upvotes"]')).to have_content(1)
      expect(first('[data-testid="issuable-downvotes"]')).to have_content(1)
    end

    it 'sorts labels alphabetically' do
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

  it "counts merge requests closing issues icons for each issue" do
    visit_issuable_list(:issue)

    expect(page).to have_selector('[data-testid="merge-requests"]', count: 1)
    expect(first('[data-testid="merge-requests"]').find(:xpath, '..')).to have_content(1)
  end

  def visit_issuable_list(issuable_type)
    if issuable_type == :issue
      visit project_work_items_path(project)
    else
      visit project_merge_requests_path(project)
    end
  end

  def create_issuable(issuable_type)
    if issuable_type == :issue
      create(:issue, project: project)
    else
      create(:merge_request, :unique_branches, source_project: project)
    end
  end

  def create_issuables(issuable_type)
    3.times do
      issuable =
        if issuable_type == :issue
          create(:issue, project: project, author: user)
        else
          create(:merge_request, :unique_branches, :with_head_pipeline, source_project: project)
        end

      create_list(:note_on_issue, 2, noteable: issuable, project: project)

      create(:award_emoji, :downvote, awardable: issuable)
      create(:award_emoji, :upvote, awardable: issuable)
    end

    if issuable_type == :issue
      issue = Issue.reorder(:iid).first
      merge_request = create(:merge_request, :unique_branches, source_project: project)

      create(:merge_requests_closing_issues, issue: issue, merge_request: merge_request)
    end
  end
end
