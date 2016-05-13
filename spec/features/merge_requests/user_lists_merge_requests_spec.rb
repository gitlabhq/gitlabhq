require 'spec_helper'

describe 'Projects > Merge requests > User lists merge requests', feature: true do
  include SortingHelper

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before do
    @fix = create(:merge_request,
                  title: 'fix',
                  source_project: project,
                  source_branch: 'fix',
                  assignee: user,
                  milestone: create(:milestone, due_date: '2013-12-11'),
                  created_at: 1.minute.ago,
                  updated_at: 1.minute.ago)
    create(:merge_request,
           title: 'markdown',
           source_project: project,
           source_branch: 'markdown',
           assignee: user,
           milestone: create(:milestone, due_date: '2013-12-12'),
           created_at: 2.minutes.ago,
           updated_at: 2.minutes.ago)
    create(:merge_request,
           title: 'lfs',
           source_project: project,
           source_branch: 'lfs',
           created_at: 3.minutes.ago,
           updated_at: 10.seconds.ago)
  end

  it 'filters on no assignee' do
    visit_merge_requests(project, assignee_id: IssuableFinder::NONE)

    expect(current_path).to eq(namespace_project_merge_requests_path(project.namespace, project))
    expect(page).to have_content 'lfs'
    expect(page).not_to have_content 'fix'
    expect(page).not_to have_content 'markdown'
  end

  it 'filters on a specific assignee' do
    visit_merge_requests(project, assignee_id: user.id)

    expect(page).not_to have_content 'lfs'
    expect(page).to have_content 'fix'
    expect(page).to have_content 'markdown'
  end

  it 'sorts by newest' do
    visit_merge_requests(project, sort: sort_value_recently_created)

    expect(first_merge_request).to include('lfs')
    expect(last_merge_request).to include('fix')
  end

  it 'sorts by oldest' do
    visit_merge_requests(project, sort: sort_value_oldest_created)

    expect(first_merge_request).to include('fix')
    expect(last_merge_request).to include('lfs')
  end

  it 'sorts by last updated' do
    visit_merge_requests(project, sort: sort_value_recently_updated)

    expect(first_merge_request).to include('lfs')
  end

  it 'sorts by oldest updated' do
    visit_merge_requests(project, sort: sort_value_oldest_updated)

    expect(first_merge_request).to include('markdown')
  end

  it 'sorts by milestone due soon' do
    visit_merge_requests(project, sort: sort_value_milestone_soon)

    expect(first_merge_request).to include('fix')
  end

  it 'sorts by milestone due later' do
    visit_merge_requests(project, sort: sort_value_milestone_later)

    expect(first_merge_request).to include('markdown')
  end

  it 'filters on one label and sorts by due soon' do
    label = create(:label, project: project)
    create(:label_link, label: label, target: @fix)

    visit_merge_requests(project, label_name: [label.name],
                                  sort: sort_value_due_date_soon)

    expect(first_merge_request).to include('fix')
  end

  context 'while filtering on two labels' do
    let(:label) { create(:label, project: project) }
    let(:label2) { create(:label, project: project) }

    before do
      create(:label_link, label: label, target: @fix)
      create(:label_link, label: label2, target: @fix)
    end

    it 'sorts by due soon' do
      visit_merge_requests(project, label_name: [label.name, label2.name],
                                    sort: sort_value_due_date_soon)

      expect(first_merge_request).to include('fix')
    end

    context 'filter on assignee and' do
      it 'sorts by due soon' do
        visit_merge_requests(project, label_name: [label.name, label2.name],
                                      assignee_id: user.id,
                                      sort: sort_value_due_date_soon)

        expect(first_merge_request).to include('fix')
      end
    end
  end

  def visit_merge_requests(project, opts = {})
    visit namespace_project_merge_requests_path(project.namespace, project, opts)
  end

  def first_merge_request
    page.all('ul.mr-list > li').first.text
  end

  def last_merge_request
    page.all('ul.mr-list > li').last.text
  end
end
