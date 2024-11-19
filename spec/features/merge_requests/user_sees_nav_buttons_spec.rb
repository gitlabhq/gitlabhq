# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees nav buttons', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_guest(guest)
  end

  context 'as a maintainer' do
    before do
      sign_in(maintainer)

      visit project_merge_requests_path(project)
    end

    it 'shows the "New merge request" button' do
      expect(page).to have_link 'New merge request', href: project_new_merge_request_path(project)
    end

    it 'shows the "Bulk edit" button' do
      expect(page).to have_button 'Bulk edit'
    end

    it 'does not show the "Merge trains" button' do
      expect(page).not_to have_link 'Merge trains'
    end
  end

  context 'as a guest' do
    before do
      sign_in(guest)

      visit project_merge_requests_path(project)
    end

    it 'does not show the "New merge request" button' do
      expect(page).not_to have_link 'New merge request'
    end

    it 'does not show the "Bulk edit" button' do
      expect(page).not_to have_button 'Bulk edit'
    end

    it 'does not show the "Merge trains" button' do
      expect(page).not_to have_link 'Merge trains'
    end
  end
end
