require 'rails_helper'

describe 'Merge request', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.team << [user, :master]
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

  context 'view merge request with MWPS enabled but fast-forward merge is not possible' do
    before do
      project.update(merge_requests_ff_only_enabled: true)

      merge_request.update(
        merge_when_pipeline_succeeds: true,
        merge_user: merge_request.author,
        state: :can_be_merged
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

  context 'user can merge into source project but cannot push to fork', js: true do
    let(:fork_project) { create(:project, :public) }
    let(:user2) { create(:user) }

    before do
      project.team << [user2, :master]
      sign_out(:user)
      sign_in(user2)
      merge_request.update(target_project: fork_project)
      visit project_merge_request_path(project, merge_request)
    end

    it 'user can merge into the source project' do
      expect(page).to have_button('Merge', disabled: false)
    end

    it 'user cannot remove source branch' do
      expect(page).to have_field('remove-source-branch-input', disabled: true)
    end
  end
end
