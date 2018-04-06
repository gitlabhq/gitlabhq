require 'spec_helper'

feature 'Dashboard Merge Requests' do
  include Spec::Support::Helpers::Features::SortingHelpers
  include FilterItemSelectHelper
  include ProjectForksHelper

  let(:current_user) { create :user }
  let(:project) { create(:project) }

  let(:public_project) { create(:project, :public, :repository) }
  let(:forked_project) { fork_project(public_project, current_user, repository: true) }

  before do
    project.add_master(current_user)
    sign_in(current_user)
  end

  context 'new merge request dropdown' do
    let(:project_with_disabled_merge_requests) { create(:project, :merge_requests_disabled) }

    before do
      project_with_disabled_merge_requests.add_master(current_user)
      visit merge_requests_dashboard_path
    end

    it 'shows projects only with merge requests feature enabled', :js do
      find('.new-project-item-select-button').click

      page.within('.select2-results') do
        expect(page).to have_content(project.full_name)
        expect(page).not_to have_content(project_with_disabled_merge_requests.full_name)
      end
    end
  end

  context 'no merge requests exist' do
    it 'shows an empty state' do
      visit merge_requests_dashboard_path(assignee_id: current_user.id)

      expect(page).to have_selector('.empty-state')
    end
  end

  context 'merge requests exist' do
    let!(:assigned_merge_request) do
      create(:merge_request,
        assignee: current_user,
        source_project: project,
        author: create(:user))
    end

    let!(:assigned_merge_request_from_fork) do
      create(:merge_request,
              source_branch: 'markdown', assignee: current_user,
              target_project: public_project, source_project: forked_project,
              author: create(:user))
    end

    let!(:authored_merge_request) do
      create(:merge_request,
              source_branch: 'markdown',
              source_project: project,
              author: current_user)
    end

    let!(:authored_merge_request_from_fork) do
      create(:merge_request,
              source_branch: 'feature_conflict',
              author: current_user,
              target_project: public_project, source_project: forked_project)
    end

    let!(:other_merge_request) do
      create(:merge_request,
              source_branch: 'fix',
              source_project: project,
              author: create(:user))
    end

    before do
      visit merge_requests_dashboard_path(assignee_id: current_user.id)
    end

    it 'shows assigned merge requests' do
      expect(page).to have_content(assigned_merge_request.title)
      expect(page).to have_content(assigned_merge_request_from_fork.title)

      expect(page).not_to have_content(authored_merge_request.title)
      expect(page).not_to have_content(authored_merge_request_from_fork.title)
      expect(page).not_to have_content(other_merge_request.title)
    end

    it 'shows authored merge requests', :js do
      filter_item_select('Any Assignee', '.js-assignee-search')
      filter_item_select(current_user.to_reference, '.js-author-search')

      expect(page).to have_content(authored_merge_request.title)
      expect(page).to have_content(authored_merge_request_from_fork.title)

      expect(page).not_to have_content(assigned_merge_request.title)
      expect(page).not_to have_content(assigned_merge_request_from_fork.title)
      expect(page).not_to have_content(other_merge_request.title)
    end

    it 'shows all merge requests', :js do
      filter_item_select('Any Assignee', '.js-assignee-search')
      filter_item_select('Any Author', '.js-author-search')

      expect(page).to have_content(authored_merge_request.title)
      expect(page).to have_content(authored_merge_request_from_fork.title)
      expect(page).to have_content(assigned_merge_request.title)
      expect(page).to have_content(assigned_merge_request_from_fork.title)
      expect(page).to have_content(other_merge_request.title)
    end

    it 'shows sorted merge requests' do
      sort_by('Created date')

      visit merge_requests_dashboard_path(assignee_id: current_user.id)

      expect(find('.issues-filters')).to have_content('Created date')
    end

    it 'keeps sorting merge requests after visiting Projects MR page' do
      sort_by('Created date')

      visit project_merge_requests_path(project)

      expect(find('.issues-filters')).to have_content('Created date')
    end
  end
end
