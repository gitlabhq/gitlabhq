require 'spec_helper'

feature 'Groups Merge Requests Empty States' do
  let(:group) { create(:group) }
  let(:user) { create(:group_member, :developer, user: create(:user), group: group ).user }

  before do
    sign_in(user)
  end

  context 'group has a project' do
    let(:project) { create(:empty_project, namespace: group) }

    before do
      project.add_master(user)
    end

    context 'the project has a merge request' do
      before do
        create(:merge_request, source_project: project)

        visit merge_requests_group_path(group)
      end

      it 'should not display an empty state' do
        expect(page).not_to have_selector('.empty-state')
      end
    end

    context 'the project has no merge requests', :js do
      before do
        visit merge_requests_group_path(group)
      end

      it 'should display an empty state' do
        expect(page).to have_selector('.empty-state')
      end

      it 'should show a new merge request button' do
        within '.empty-state' do
          expect(page).to have_content('New merge request')
        end
      end

      it 'the new merge request button opens a project dropdown' do
        within '.empty-state' do
          find('.new-project-item-select-button').click
        end

        expect(page).to have_selector('.ajax-project-dropdown')
      end
    end
  end

  context 'group without a project' do
    before do
      visit merge_requests_group_path(group)
    end

    it 'should display an empty state' do
      expect(page).to have_selector('.empty-state')
    end

    it 'should not show a new merge request button' do
      within '.empty-state' do
        expect(page).not_to have_link('New merge request')
      end
    end
  end
end
