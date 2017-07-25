require 'spec_helper'

feature 'Group merge requests page' do
  let(:path) { merge_requests_group_path(group) }
  let(:issuable) { create(:merge_request, source_project: project, target_project: project, title: 'this is my created issuable') }

  include_examples 'project features apply to issuables', MergeRequest

  context 'archived issuable' do
    let(:project_archived) { create(:project, :archived, :merge_requests_enabled, group: group) }
    let(:issuable_archived) { create(:merge_request, source_project: project_archived, target_project: project_archived, title: 'issuable of an archived project') }
    let(:access_level) { ProjectFeature::ENABLED }
    let(:user) { user_in_group }

    before do
      issuable_archived
      visit path
    end

    it 'hides archived merge requests' do
      expect(page).to have_content(issuable.title)
      expect(page).not_to have_content(issuable_archived.title)
    end

    it 'ignores archived merge request count badges in navbar' do
      expect( page.find('[title="Merge Requests"] span.badge.count').text).to eq("1")
    end

    it 'ignores archived merge request count badges in state-filters' do
      expect(page.find('#state-opened span.badge').text).to eq("1")
      expect(page.find('#state-merged span.badge').text).to eq("0")
      expect(page.find('#state-closed span.badge').text).to eq("0")
      expect(page.find('#state-all span.badge').text).to eq("1")
    end
  end
end
