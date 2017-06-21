require 'rails_helper'

feature 'Merge Request filtering by Milestone', feature: true do
  include FilteredSearchHelpers
  include MergeRequestHelpers

  let(:project)   { create(:project, :public) }
  let!(:user)     { create(:user)}
  let(:milestone) { create(:milestone, project: project) }

  def filter_by_milestone(title)
    find(".js-milestone-select").click
    find(".milestone-filter a", text: title).click
  end

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  scenario 'filters by no Milestone', js: true do
    create(:merge_request, :with_diffs, source_project: project)
    create(:merge_request, :simple, source_project: project, milestone: milestone)

    visit_merge_requests(project)
    input_filtered_search('milestone:none')

    expect_tokens([{ name: 'milestone', value: 'none' }])
    expect_filtered_search_input_empty

    expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
    expect(page).to have_css('.merge-request', count: 1)
  end

  context 'filters by upcoming milestone', js: true do
    it 'does not show merge requests with no expiry' do
      create(:merge_request, :with_diffs, source_project: project)
      create(:merge_request, :simple, source_project: project, milestone: milestone)

      visit_merge_requests(project)
      input_filtered_search('milestone:upcoming')

      expect(page).to have_css('.merge-request', count: 0)
    end

    it 'shows merge requests in future' do
      milestone = create(:milestone, project: project, due_date: Date.tomorrow)
      create(:merge_request, :with_diffs, source_project: project)
      create(:merge_request, :simple, source_project: project, milestone: milestone)

      visit_merge_requests(project)
      input_filtered_search('milestone:upcoming')

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_css('.merge-request', count: 1)
    end

    it 'does not show merge requests in past' do
      milestone = create(:milestone, project: project, due_date: Date.yesterday)
      create(:merge_request, :with_diffs, source_project: project)
      create(:merge_request, :simple, source_project: project, milestone: milestone)

      visit_merge_requests(project)
      input_filtered_search('milestone:upcoming')

      expect(page).to have_css('.merge-request', count: 0)
    end
  end

  scenario 'filters by a specific Milestone', js: true do
    create(:merge_request, :with_diffs, source_project: project, milestone: milestone)
    create(:merge_request, :simple, source_project: project)

    visit_merge_requests(project)
    input_filtered_search("milestone:%'#{milestone.title}'")

    expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
    expect(page).to have_css('.merge-request', count: 1)
  end

  context 'when milestone has single quotes in title' do
    background do
      milestone.update(name: "rock 'n' roll")
    end

    scenario 'filters by a specific Milestone', js: true do
      create(:merge_request, :with_diffs, source_project: project, milestone: milestone)
      create(:merge_request, :simple, source_project: project)

      visit_merge_requests(project)
      input_filtered_search("milestone:%\"#{milestone.title}\"")

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_css('.merge-request', count: 1)
    end
  end
end
