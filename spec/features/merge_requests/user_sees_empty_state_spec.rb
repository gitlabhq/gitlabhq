# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees empty state', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'shows an empty state and a "New merge request" button' do
    visit project_merge_requests_path(project)

    expect(page).to have_selector('.gl-empty-state')
    expect(page).to have_link 'New merge request', href: project_new_merge_request_path(project)
  end

  context 'if there are merge requests' do
    before do
      create(:merge_request, source_project: project)
    end

    it 'does not show an empty state' do
      visit project_merge_requests_path(project)

      expect(page).not_to have_selector('.gl-empty-state')
    end

    it 'shows empty state when filter results empty' do
      visit project_merge_requests_path(project, milestone_title: "1.0")

      expect(page).to have_selector('.gl-empty-state')
      expect(page).to have_content('No results found')
      expect(page).to have_content('Edit your search and try again.')
    end
  end

  context 'as member of a fork' do
    let(:fork_user) { create(:user) }
    let(:forked_project) { fork_project(project, fork_user, namespace: fork_user.namespace, repository: true) }

    before do
      forked_project.add_maintainer(fork_user)
      sign_in(fork_user)
    end

    it 'shows empty state when filter results empty' do
      visit project_merge_requests_path(project, search: 'foo')

      expect(page).to have_selector('.gl-empty-state')
      within('.gl-empty-state') do
        expect(page).to have_link 'New merge request', href: /#{project_new_merge_request_path(forked_project)}$/
      end
    end
  end
end
