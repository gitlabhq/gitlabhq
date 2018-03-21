require 'rails_helper'

describe 'Merge request > User sees merge widget', :js do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:project_only_mwps) { create(:project, :repository, only_allow_merge_if_pipeline_succeeds: true) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:merge_request_in_only_mwps_project) { create(:merge_request, source_project: project_only_mwps) }

  before do
    project.add_master(user)
    project_only_mwps.add_master(user)
    sign_in(user)
  end

  context 'new merge request' do
    before do
      visit project_new_merge_request_path(
        project,
        merge_request: {
          source_project_id: project.id,
          target_project_id: project.id,
          source_branch: 'feature',
          target_branch: 'master'
        })
    end

    it 'shows widget status after creating new merge request' do
      click_button 'Submit merge request'

      wait_for_requests

      expect(page).to have_selector('.accept-merge-request')
      expect(find('.accept-merge-request')['disabled']).not_to be(true)
    end
  end

  context 'view merge request' do
    let!(:environment) { create(:environment, project: project) }

    let!(:deployment) do
      create(:deployment, environment: environment,
                          ref: 'feature',
                          sha: merge_request.diff_head_sha)
    end

    before do
      visit project_merge_request_path(project, merge_request)
    end

    it 'shows environments link' do
      wait_for_requests

      page.within('.mr-widget-heading') do
        expect(page).to have_content("Deployed to #{environment.name}")
        expect(find('.js-deploy-url')[:href]).to include(environment.formatted_external_url)
      end
    end

    it 'shows green accept merge request button' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests
      expect(page).to have_selector('.accept-merge-request')
      expect(find('.accept-merge-request')['disabled']).not_to be(true)
    end

    it 'allows me to merge, see cherry-pick modal and load branches list' do
      wait_for_requests
      click_button 'Merge'

      wait_for_requests
      click_link 'Cherry-pick'
      page.find('.js-project-refs-dropdown').click
      wait_for_requests

      expect(page.all('.js-cherry-pick-form .dropdown-content li').size).to be > 1
    end
  end

  context 'view merge request with external CI service' do
    before do
      create(:service, project: project,
                       active: true,
                       type: 'CiService',
                       category: 'ci')

      visit project_merge_request_path(project, merge_request)
    end

    it 'has danger button while waiting for external CI status' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests
      expect(page).to have_selector('.accept-merge-request.btn-danger')
    end
  end

  context 'view merge request with failed GitLab CI pipelines' do
    before do
      commit_status = create(:commit_status, project: project, status: 'failed')
      pipeline = create(:ci_pipeline, project: project,
                                      sha: merge_request.diff_head_sha,
                                      ref: merge_request.source_branch,
                                      status: 'failed',
                                      statuses: [commit_status],
                                      head_pipeline_of: merge_request)
      create(:ci_build, :pending, pipeline: pipeline)

      visit project_merge_request_path(project, merge_request)
    end

    it 'has danger button when not succeeded' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests
      expect(page).to have_selector('.accept-merge-request.btn-danger')
    end
  end

  context 'when merge request is in the blocked pipeline state' do
    before do
      create(
        :ci_pipeline,
        project: project,
        sha: merge_request.diff_head_sha,
        ref: merge_request.source_branch,
        status: :manual,
        head_pipeline_of: merge_request)

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows information about blocked pipeline' do
      expect(page).to have_content("Pipeline blocked")
      expect(page).to have_content(
        "The pipeline for this merge request requires a manual action")
      expect(page).to have_css('.ci-status-icon-manual')
    end
  end

  context 'view merge request with MWBS button' do
    before do
      commit_status = create(:commit_status, project: project, status: 'pending')
      pipeline = create(:ci_pipeline, project: project,
                                      sha: merge_request.diff_head_sha,
                                      ref: merge_request.source_branch,
                                      status: 'pending',
                                      statuses: [commit_status],
                                      head_pipeline_of: merge_request)
      create(:ci_build, :pending, pipeline: pipeline)

      visit project_merge_request_path(project, merge_request)
    end

    it 'has info button when MWBS button' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests
      expect(page).to have_selector('.accept-merge-request.btn-info')
    end
  end

  context 'view merge request where project has CI setup but no CI status' do
    before do
      pipeline = create(:ci_pipeline, project: project,
                                      sha: merge_request.diff_head_sha,
                                      ref: merge_request.source_branch)
      create(:ci_build, pipeline: pipeline)

      visit project_merge_request_path(project, merge_request)
    end

    it 'has pipeline error text' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      expect(page).to have_text('Could not connect to the CI server. Please check your settings and try again')
    end
  end

  context 'view merge request in project with only-mwps setting enabled but no CI is setup' do
    before do
      visit project_merge_request_path(project_only_mwps, merge_request_in_only_mwps_project)
    end

    it 'should be allowed to merge' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      expect(page).to have_selector('.accept-merge-request')
      expect(find('.accept-merge-request')['disabled']).not_to be(true)
    end
  end

  context 'view merge request with MWPS enabled but automatically merge fails' do
    before do
      merge_request.update(
        merge_when_pipeline_succeeds: true,
        merge_user: merge_request.author,
        merge_error: 'Something went wrong'
      )

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows information about the merge error' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      page.within('.mr-widget-body') do
        expect(page).to have_content('Something went wrong')
      end
    end
  end

  context 'view merge request with MWPS enabled but automatically merge fails' do
    before do
      merge_request.update(
        merge_when_pipeline_succeeds: true,
        merge_user: merge_request.author,
        merge_error: 'Something went wrong'
      )

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows information about the merge error' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      page.within('.mr-widget-body') do
        expect(page).to have_content('Something went wrong')
      end
    end
  end

  context 'view merge request where fast-forward merge is not possible' do
    before do
      project.update(merge_requests_ff_only_enabled: true)

      merge_request.update(
        merge_user: merge_request.author,
        merge_status: :cannot_be_merged
      )

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows information about the merge error' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      page.within('.mr-widget-body') do
        expect(page).to have_content('Fast-forward merge is not possible')
      end
    end
  end

  context 'merge error' do
    before do
      allow_any_instance_of(Repository).to receive(:merge).and_return(false)
      visit project_merge_request_path(project, merge_request)
    end

    it 'updates the MR widget' do
      click_button 'Merge'

      page.within('.mr-widget-body') do
        expect(page).to have_content('Conflicts detected during merge')
      end
    end
  end

  context 'user can merge into source project but cannot push to fork', :js do
    let(:fork_project) { create(:project, :public, :repository) }
    let(:user2) { create(:user) }

    before do
      project.add_master(user2)
      sign_out(:user)
      sign_in(user2)
      merge_request.update(target_project: fork_project)
      visit project_merge_request_path(project, merge_request)
    end

    it 'user can merge into the source project' do
      expect(page).to have_button('Merge', disabled: false)
    end

    it 'user cannot remove source branch' do
      expect(page).not_to have_field('remove-source-branch-input')
    end
  end

  context 'user cannot merge project and cannot push to fork', :js do
    let(:forked_project) { fork_project(project, nil, repository: true) }
    let(:user2) { create(:user) }

    before do
      project.add_developer(user2)
      sign_out(:user)
      sign_in(user2)
      merge_request.update(
        source_project: forked_project,
        target_project: project,
        merge_params: { 'force_remove_source_branch' => '1' }
      )
      visit project_merge_request_path(project, merge_request)
    end

    it 'user cannot remove source branch' do
      expect(page).not_to have_field('remove-source-branch-input')
      expect(page).to have_content('Removes source branch')
    end
  end

  context 'ongoing merge process' do
    it 'shows Merging state' do
      allow_any_instance_of(MergeRequest).to receive(:merge_ongoing?).and_return(true)

      visit project_merge_request_path(project, merge_request)

      wait_for_requests

      expect(page).not_to have_button('Merge')
      expect(page).to have_content('This merge request is in the process of being merged')
    end
  end
end
