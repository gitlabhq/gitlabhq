require 'rails_helper'

describe 'Merge Requests > User filters by milestones', :js do
  include FilteredSearchHelpers

  let(:project)   { create(:project, :public, :repository) }
  let(:user)      { project.creator }
  let(:milestone) { create(:milestone, project: project) }

  before do
    create(:merge_request, :with_diffs, source_project: project)
    create(:merge_request, :simple, source_project: project, milestone: milestone)

    sign_in(user)
    visit project_merge_requests_path(project)
  end

  it 'filters by no milestone' do
    input_filtered_search('milestone:none')

    expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
    expect(page).to have_css('.merge-request', count: 1)
  end

  it 'filters by a specific milestone' do
    input_filtered_search("milestone:%'#{milestone.title}'")

    expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
    expect(page).to have_css('.merge-request', count: 1)
  end

  describe 'filters by upcoming milestone' do
    it 'does not show merge requests with no expiry' do
      input_filtered_search('milestone:upcoming')

      expect(page).to have_issuable_counts(open: 0, closed: 0, all: 0)
      expect(page).to have_css('.merge-request', count: 0)
    end

    context 'with an upcoming milestone' do
      let(:milestone) { create(:milestone, project: project, due_date: Date.tomorrow) }

      it 'shows merge requests' do
        input_filtered_search('milestone:upcoming')

        expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
        expect(page).to have_css('.merge-request', count: 1)
      end
    end

    context 'with a due milestone' do
      let(:milestone) { create(:milestone, project: project, due_date: Date.yesterday) }

      it 'does not show any merge requests' do
        input_filtered_search('milestone:upcoming')

        expect(page).to have_issuable_counts(open: 0, closed: 0, all: 0)
        expect(page).to have_css('.merge-request', count: 0)
      end
    end
  end
end
