require 'spec_helper'

describe 'Projects > Issuables > Default sort order' do
  let(:project) { create(:project, :public) }

  let(:first_created_issuable) { issuables.order_created_asc.first }
  let(:last_created_issuable) { issuables.order_created_desc.first }

  let(:first_updated_issuable) { issuables.order_updated_asc.first }
  let(:last_updated_issuable) { issuables.order_updated_desc.first }

  context 'for merge requests' do
    include MergeRequestHelpers

    let!(:issuables) do
      timestamps = [{ created_at: 3.minutes.ago, updated_at: 20.seconds.ago },
                    { created_at: 2.minutes.ago, updated_at: 30.seconds.ago },
                    { created_at: 4.minutes.ago, updated_at: 10.seconds.ago }]

      timestamps.each_with_index do |ts, i|
        create issuable_type, { title: "#{issuable_type}_#{i}",
                                source_branch: "#{issuable_type}_#{i}",
                                source_project: project }.merge(ts)
      end

      MergeRequest.all
    end

    context 'in the "merge requests" tab', :js do
      let(:issuable_type) { :merge_request }

      it 'is "last created"' do
        visit_merge_requests project

        expect(first_merge_request).to include(last_created_issuable.title)
        expect(last_merge_request).to include(first_created_issuable.title)
      end
    end

    context 'in the "merge requests / open" tab', :js do
      let(:issuable_type) { :merge_request }

      it 'is "created date"' do
        visit_merge_requests_with_state(project, 'open')

        expect(selected_sort_order).to eq('created date')
        expect(first_merge_request).to include(last_created_issuable.title)
        expect(last_merge_request).to include(first_created_issuable.title)
      end
    end

    context 'in the "merge requests / merged" tab', :js do
      let(:issuable_type) { :merged_merge_request }

      it 'is "last updated"' do
        visit_merge_requests_with_state(project, 'merged')

        expect(find('.issues-other-filters')).to have_content('Last updated')
        expect(first_merge_request).to include(last_updated_issuable.title)
        expect(last_merge_request).to include(first_updated_issuable.title)
      end
    end

    context 'in the "merge requests / closed" tab', :js do
      let(:issuable_type) { :closed_merge_request }

      it 'is "last updated"' do
        visit_merge_requests_with_state(project, 'closed')

        expect(find('.issues-other-filters')).to have_content('Last updated')
        expect(first_merge_request).to include(last_updated_issuable.title)
        expect(last_merge_request).to include(first_updated_issuable.title)
      end
    end

    context 'in the "merge requests / all" tab', :js do
      let(:issuable_type) { :merge_request }

      it 'is "created date"' do
        visit_merge_requests_with_state(project, 'all')

        expect(find('.issues-other-filters')).to have_content('Created date')
        expect(first_merge_request).to include(last_created_issuable.title)
        expect(last_merge_request).to include(first_created_issuable.title)
      end
    end
  end

  context 'for issues' do
    include IssueHelpers

    let!(:issuables) do
      timestamps = [{ created_at: 3.minutes.ago, updated_at: 20.seconds.ago },
                    { created_at: 2.minutes.ago, updated_at: 30.seconds.ago },
                    { created_at: 4.minutes.ago, updated_at: 10.seconds.ago }]

      timestamps.each_with_index do |ts, i|
        create issuable_type, { title: "#{issuable_type}_#{i}",
                                project: project }.merge(ts)
      end

      Issue.all
    end

    context 'in the "issues" tab', :js do
      let(:issuable_type) { :issue }

      it 'is "created date"' do
        visit_issues project

        expect(find('.issues-other-filters')).to have_content('Created date')
        expect(first_issue).to include(last_created_issuable.title)
        expect(last_issue).to include(first_created_issuable.title)
      end
    end

    context 'in the "issues / open" tab', :js do
      let(:issuable_type) { :issue }

      it 'is "created date"' do
        visit_issues_with_state(project, 'open')

        expect(find('.issues-other-filters')).to have_content('Created date')
        expect(first_issue).to include(last_created_issuable.title)
        expect(last_issue).to include(first_created_issuable.title)
      end
    end

    context 'in the "issues / closed" tab', :js do
      let(:issuable_type) { :closed_issue }

      it 'is "last updated"' do
        visit_issues_with_state(project, 'closed')

        expect(find('.issues-other-filters')).to have_content('Last updated')
        expect(first_issue).to include(last_updated_issuable.title)
        expect(last_issue).to include(first_updated_issuable.title)
      end
    end

    context 'in the "issues / all" tab', :js do
      let(:issuable_type) { :issue }

      it 'is "created date"' do
        visit_issues_with_state(project, 'all')

        expect(find('.issues-other-filters')).to have_content('Created date')
        expect(first_issue).to include(last_created_issuable.title)
        expect(last_issue).to include(first_created_issuable.title)
      end
    end

    context 'when the sort in the URL is id_desc' do
      let(:issuable_type) { :issue }

      before do
        visit_issues(project, sort: 'id_desc')
      end

      it 'shows the sort order as created date' do
        expect(find('.issues-other-filters')).to have_content('Created date')
        expect(first_issue).to include(last_created_issuable.title)
        expect(last_issue).to include(first_created_issuable.title)
      end
    end
  end

  def selected_sort_order
    find('.filter-dropdown-container .dropdown button').text.downcase
  end

  def visit_merge_requests_with_state(project, state)
    visit_merge_requests project, state: state
  end

  def visit_issues_with_state(project, state)
    visit_issues project, state: state
  end
end
