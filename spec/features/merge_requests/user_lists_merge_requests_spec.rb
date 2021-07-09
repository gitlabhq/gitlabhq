# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge requests > User lists merge requests' do
  include MergeRequestHelpers
  include SortingHelper

  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:user4) { create(:user) }
  let(:user5) { create(:user) }

  before do
    @fix = create(:merge_request,
                  title: 'fix',
                  source_project: project,
                  source_branch: 'fix',
                  assignees: [user],
                  reviewers: [user, user2, user3, user4, user5],
                  milestone: create(:milestone, project: project, due_date: '2013-12-11'),
                  created_at: 1.minute.ago,
                  updated_at: 1.minute.ago)
    @fix.metrics.update_column(:merged_at, 10.seconds.ago)

    @markdown = create(:merge_request,
           title: 'markdown',
           source_project: project,
           source_branch: 'markdown',
           assignees: [user],
           reviewers: [user, user2, user3, user4],
           milestone: create(:milestone, project: project, due_date: '2013-12-12'),
           created_at: 2.minutes.ago,
           updated_at: 2.minutes.ago)
    @markdown.metrics.update_column(:merged_at, 50.seconds.ago)

    @merge_test = create(:merge_request,
           title: 'merge-test',
           source_project: project,
           source_branch: 'merge-test',
           created_at: 3.minutes.ago,
           updated_at: 10.seconds.ago)
    @merge_test.metrics.update_column(:merged_at, 10.seconds.ago)
  end

  context 'merge request reviewers' do
    before do
      visit_merge_requests(project, reviewer_id: user.id)
    end

    it 'has reviewers in MR list' do
      expect(page).to have_css('.issuable-reviewers')
    end

    it 'shows reviewers avatar count badge if more_reviewers_count > 4' do
      first_issuable_reviewers = first('.issuable-reviewers')

      expect(first_issuable_reviewers).to have_content('2')
      expect(first_issuable_reviewers).to have_css('.avatar-counter')
    end

    it 'does not show reviewers avatar count badge if more_reviewers_count <= 4' do
      expect(page.all('.issuable-reviewers')[1]).not_to have_css('.avatar-counter')
    end
  end

  it 'filters on no assignee' do
    visit_merge_requests(project, assignee_id: IssuableFinder::Params::FILTER_NONE)

    expect(current_path).to eq(project_merge_requests_path(project))
    expect(page).to have_content 'merge-test'
    expect(page).not_to have_content 'fix'
    expect(page).not_to have_content 'markdown'
    expect(count_merge_requests).to eq(1)
  end

  it 'filters on a specific assignee' do
    visit_merge_requests(project, assignee_id: user.id)

    expect(page).not_to have_content 'merge-test'
    expect(page).to have_content 'fix'
    expect(page).to have_content 'markdown'
    expect(count_merge_requests).to eq(2)
  end

  it 'sorts by newest' do
    visit_merge_requests(project, sort: sort_value_created_date)

    expect(first_merge_request).to include('fix')
    expect(last_merge_request).to include('merge-test')
    expect(count_merge_requests).to eq(3)
  end

  it 'sorts by last updated' do
    visit_merge_requests(project, sort: sort_value_recently_updated)

    expect(first_merge_request).to include('merge-test')
    expect(count_merge_requests).to eq(3)
  end

  it 'sorts by milestone' do
    visit_merge_requests(project, sort: sort_value_milestone)

    expect(first_merge_request).to include('fix')
    expect(count_merge_requests).to eq(3)
  end

  it 'sorts by merged at' do
    visit_merge_requests(project, sort: sort_value_merged_date)

    expect(first_merge_request).to include('markdown')
    expect(count_merge_requests).to eq(3)
  end

  it 'filters on one label and sorts by due date' do
    label = create(:label, project: project)
    create(:label_link, label: label, target: @fix)

    visit_merge_requests(project, label_name: [label.name],
                                  sort: sort_value_due_date)

    expect(first_merge_request).to include('fix')
    expect(count_merge_requests).to eq(1)
  end

  context 'while filtering on two labels' do
    let(:label) { create(:label, project: project) }
    let(:label2) { create(:label, project: project) }

    before do
      create(:label_link, label: label, target: @fix)
      create(:label_link, label: label2, target: @fix)
    end

    it 'sorts by due date' do
      visit_merge_requests(project, label_name: [label.name, label2.name],
                                    sort: sort_value_due_date)

      expect(first_merge_request).to include('fix')
      expect(count_merge_requests).to eq(1)
    end

    context 'filter on assignee and' do
      it 'sorts by due soon' do
        visit_merge_requests(project, label_name: [label.name, label2.name],
                                      assignee_id: user.id,
                                      sort: sort_value_due_date)

        expect(first_merge_request).to include('fix')
        expect(count_merge_requests).to eq(1)
      end

      it 'sorts by recently due milestone' do
        visit project_merge_requests_path(project,
          label_name: [label.name, label2.name],
          assignee_id: user.id,
          sort: sort_value_milestone)

        expect(first_merge_request).to include('fix')
      end
    end
  end

  def count_merge_requests
    page.all('ul.mr-list > li').count
  end
end
