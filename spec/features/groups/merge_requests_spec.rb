# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group merge requests page', :js, feature_category: :code_review_workflow do
  include FilteredSearchHelpers

  let(:path) { merge_requests_group_path(group) }
  let(:issuable) { create(:merge_request, source_project: project, target_project: project, title: 'this is my created issuable') }
  let(:access_level) { ProjectFeature::ENABLED }
  let(:user) { user_in_group }

  include_examples 'project features apply to issuables', MergeRequest

  context 'archived issuable' do
    let(:project_archived) { create(:project, :archived, :merge_requests_enabled, :repository, group: group) }
    let(:issuable_archived) { create(:merge_request, source_project: project_archived, target_project: project_archived, title: 'issuable of an archived project') }

    before do
      issuable_archived
      visit path
    end

    it 'hides archived merge requests' do
      expect(page).to have_content(issuable.title)
      expect(page).not_to have_content(issuable_archived.title)
    end

    it 'ignores archived merge request count badges in navbar', :js do
      within_testid('super-sidebar') do
        click_on 'Pinned' # to close the Pinned section to only have one match
        expect(find_link(text: 'Merge requests').find('.badge').text).to eq("1")
      end
    end

    it 'ignores archived merge request count badges in state-filters' do
      expect(page.find('.issuable-state-filters')).to have_text("Open 1")
      expect(page.find('.issuable-state-filters')).to have_text("Merged 0")
      expect(page.find('.issuable-state-filters')).to have_text("Closed 0")
      expect(page.find('.issuable-state-filters')).to have_text("All 1")
    end
  end

  context 'when merge request assignee to user' do
    before do
      issuable.update!(assignees: [user])

      visit path
    end

    it { expect(page).to have_content issuable.title[0..80] }
  end

  context 'group filtered search', :js do
    let(:user2) { user_outside_group }

    it 'filters by assignee only group users' do
      select_tokens 'Assignee', '=', submit: false

      expect_suggestion(user.name)
      expect_no_suggestion(user2.name)
    end

    it 'will still show the navbar with no results' do
      search_term = 'some-search-term-that-produces-zero-results'

      submit_search_term search_term

      expect(page).to have_content('No results found')
    end
  end

  describe 'new merge request dropdown' do
    let(:project_with_merge_requests_disabled) { create(:project, :merge_requests_disabled, group: group) }

    before do
      visit path
    end

    it 'shows projects only with merge requests feature enabled', :js do
      click_button 'Select project to create merge request'

      within_testid('new-resource-dropdown') do
        expect(page).to have_content(project.name_with_namespace)
        expect(page).not_to have_content(project_with_merge_requests_disabled.name_with_namespace)
      end
    end
  end

  context 'empty state with no merge requests' do
    before do
      MergeRequest.delete_all
    end

    it 'shows an empty state, button to create merge request and no filters bar', :aggregate_failures, :js do
      visit path

      expect(page).to have_selector('.gl-empty-state')
    end

    context 'with no open merge requests' do
      it 'shows an empty state, button to create merge request and filters bar', :aggregate_failures, :js do
        create(:merge_request, :closed, source_project: project, target_project: project)
        visit path

        expect(page).to have_selector('.gl-empty-state')
      end
    end
  end
end
