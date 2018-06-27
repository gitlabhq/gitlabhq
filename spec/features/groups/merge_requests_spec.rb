require 'spec_helper'

feature 'Group merge requests page' do
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

    it 'ignores archived merge request count badges in navbar' do
      expect(first(:link, text: 'Merge Requests').find('.badge').text).to eq("1")
    end

    it 'ignores archived merge request count badges in state-filters' do
      expect(page.find('#state-opened span.badge').text).to eq("1")
      expect(page.find('#state-merged span.badge').text).to eq("0")
      expect(page.find('#state-closed span.badge').text).to eq("0")
      expect(page.find('#state-all span.badge').text).to eq("1")
    end
  end

  context 'when merge request assignee to user' do
    before do
      issuable.update!(assignee: user)

      visit path
    end

    it { expect(page).to have_content issuable.title[0..80] }
  end

  context 'group filtered search', :js do
    let(:user2) { user_outside_group }

    it 'filters by assignee only group users' do
      filtered_search.set('assignee:')

      expect(find('#js-dropdown-assignee .filter-dropdown')).to have_content(user.name)
      expect(find('#js-dropdown-assignee .filter-dropdown')).not_to have_content(user2.name)
    end
  end
end
