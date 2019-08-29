# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User sees empty state' do
  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'shows an empty state and a "New merge request" button' do
    visit project_merge_requests_path(project)

    expect(page).to have_selector('.empty-state')
    expect(page).to have_link 'New merge request', href: project_new_merge_request_path(project)
  end

  context 'if there are merge requests' do
    before do
      create(:merge_request, source_project: project)
    end

    it 'does not show an empty state' do
      visit project_merge_requests_path(project)

      expect(page).not_to have_selector('.empty-state')
    end

    it 'shows empty state when filter results empty' do
      visit project_merge_requests_path(project, milestone_title: "1.0")

      expect(page).to have_selector('.empty-state')
      expect(page).to have_content('Sorry, your filter produced no results')
      expect(page).to have_content('To widen your search, change or remove filters above')
    end
  end
end
