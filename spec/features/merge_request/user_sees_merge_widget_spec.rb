# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees merge widget', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include TestReportsHelper
  include ReactiveCachingHelpers

  let(:project) { create(:project, :repository) }
  let(:project_only_mwps) { create(:project, :repository, only_allow_merge_if_pipeline_succeeds: true) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:merge_request_in_only_mwps_project) { create(:merge_request, source_project: project_only_mwps) }

  def click_expand_button
    find_by_testid('toggle-button').click
  end

  before do
    stub_feature_flags(mr_reports_tab: false)

    project.add_maintainer(user)
    project_only_mwps.add_maintainer(user)
    sign_in(user)
  end

  context 'new merge request', :sidekiq_might_not_need_inline do
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
      click_button 'Create merge request'

      wait_for_requests

      expect(page).to have_selector('.accept-merge-request')
      expect(find('.accept-merge-request')['disabled']).not_to be(true)
    end
  end

  context 'view merge request' do
    let!(:environment) { create(:environment, project: project) }
    let(:sha)          { project.commit(merge_request.source_branch).sha }
    let(:pipeline)     { create(:ci_pipeline, status: 'success', sha: sha, project: project, ref: merge_request.source_branch) }
    let!(:build)       { create(:ci_build, :with_deployment, :success, environment: environment.name, pipeline: pipeline) }
    let!(:deployment)  { build.deployment }

    before do
      merge_request.update!(head_pipeline: pipeline)
      deployment.update!(status: :success)
      visit project_merge_request_path(project, merge_request)
    end

    it 'shows environments link' do
      wait_for_requests

      page.within('.js-pre-deployment') do
        expect(find('.js-deploy-env-name')[:title]).to have_text(environment.name)
        expect(page).to have_content("Deployed to")
        expect(find('.js-deploy-url')[:href]).to include(environment.formatted_external_url)
      end
    end

    it 'shows green accept merge request button' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests
      expect(page).to have_selector('.accept-merge-request')
      expect(find('.accept-merge-request')['disabled']).not_to be(true)
    end

    it 'allows me to merge, see cherry-pick modal and load branches list', :sidekiq_might_not_need_inline do
      wait_for_requests
      click_button 'Merge'

      wait_for_requests

      page.refresh

      click_button 'Cherry-pick'

      within_testid('modal-commit') do
        click_button 'master'
      end

      within_testid('modal-commit') do
        within_testid('base-dropdown-menu') do
          fill_in 'Search branches', with: ''

          wait_for_requests

          expect(page).to have_selector('[data-testid="listbox-item-master"]', visible: true)
        end
      end
    end
  end

  context 'view merge request with external CI service' do
    before do
      create(:drone_ci_integration, project: project)

      visit project_merge_request_path(project, merge_request)
    end

    it 'has merge button with confirm variant while waiting for external CI status' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      expect(page).to have_selector('.accept-merge-request.btn-confirm')
    end
  end

  context 'view merge request with failed GitLab CI pipelines' do
    before do
      commit_status = create(:commit_status, project: project, status: 'failed')
      pipeline = create(
        :ci_pipeline,
        project: project,
        sha: merge_request.diff_head_sha,
        ref: merge_request.source_branch,
        status: 'failed',
        statuses: [commit_status],
        head_pipeline_of: merge_request
      )
      create(:ci_build, :pending, pipeline: pipeline)

      visit project_merge_request_path(project, merge_request)
    end

    it 'has merge button that shows modal when pipeline does not succeeded' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      click_button 'Merge...'

      expect(page).to have_selector('[data-testid="merge-failed-pipeline-confirmation-dialog"]', visible: true)
    end

    it 'allows me to merge with a failed pipeline', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/449599' do
      wait_for_requests

      click_button 'Merge...'

      within_testid('merge-failed-pipeline-confirmation-dialog') do
        click_button 'Merge unverified changes'
      end

      expect(find_by_testid('merging-state')).to have_content('Merging!')
    end
  end

  context 'when merge request is in the blocked pipeline state and pipeline must succeed' do
    before do
      project.update_attribute(:only_allow_merge_if_pipeline_succeeds, true)

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
      click_button 'Expand merge checks'

      expect(page).to have_content("Merge blocked")
      expect(page).to have_content("Pipeline must succeed.")
      expect(page).to have_css('[data-testid="status_manual_borderless-icon"]')
    end
  end

  context 'when merge request has a branch pipeline as the head pipeline' do
    let!(:pipeline) do
      create(:ci_pipeline,
        ref: merge_request.source_branch,
        sha: merge_request.source_branch_sha,
        project: merge_request.source_project)
    end

    before do
      merge_request.update_head_pipeline
      visit project_merge_request_path(project, merge_request)
    end

    it 'shows head pipeline information' do
      within '.ci-widget-content' do
        expect(page).to have_content("Pipeline ##{pipeline.id} pending")
        expect(page).to have_content("Pipeline pending " \
                                     "for #{pipeline.short_sha} " \
                                     "on #{pipeline.ref}")
      end
    end
  end

  context 'when merge request has a detached merge request pipeline as the head pipeline' do
    let(:merge_request) do
      create(:merge_request,
        :with_detached_merge_request_pipeline,
        source_project: source_project,
        target_project: target_project)
    end

    let!(:pipeline) do
      merge_request.all_pipelines.last
    end

    let(:source_project) { project }
    let(:target_project) { project }

    before do
      merge_request.update_head_pipeline
      visit project_merge_request_path(project, merge_request)
    end

    shared_examples 'pipeline widget' do
      it 'shows head pipeline information', :sidekiq_might_not_need_inline do
        within '.ci-widget-content' do
          expect(page).to have_content("Merge request pipeline ##{pipeline.id} pending")
          expect(page).to have_content("Merge request pipeline pending for #{pipeline.short_sha}")
        end
      end
    end

    include_examples 'pipeline widget'

    context 'when source project is a forked project' do
      let(:source_project) { fork_project(project, user, repository: true) }

      include_examples 'pipeline widget'
    end
  end

  context 'when merge request has a merge request pipeline as the head pipeline' do
    let(:merge_request) do
      create(:merge_request,
        :with_merge_request_pipeline,
        source_project: source_project,
        target_project: target_project,
        merge_sha: merge_sha)
    end

    let!(:pipeline) do
      merge_request.all_pipelines.last
    end

    let(:source_project) { project }
    let(:target_project) { project }
    let(:merge_sha) { project.commit.sha }

    before do
      merge_request.update_head_pipeline
      visit project_merge_request_path(project, merge_request)
    end

    shared_examples 'pipeline widget' do
      it 'shows head pipeline information', :sidekiq_might_not_need_inline do
        within '.ci-widget-content' do
          expect(page).to have_content("Merged results pipeline ##{pipeline.id} pending")
          expect(page).to have_content("Merged results pipeline pending for #{pipeline.short_sha}")
        end
      end
    end

    include_examples 'pipeline widget'

    context 'when source project is a forked project' do
      let(:source_project) { fork_project(project, user, repository: true) }
      let(:merge_sha) { source_project.commit.sha }

      include_examples 'pipeline widget'
    end
  end

  context 'view merge request with MWBS button' do
    before do
      commit_status = create(:commit_status, project: project, status: 'pending')
      pipeline = create(
        :ci_pipeline,
        project: project,
        sha: merge_request.diff_head_sha,
        ref: merge_request.source_branch,
        status: 'pending',
        statuses: [commit_status],
        head_pipeline_of: merge_request
      )
      create(:ci_build, :pending, pipeline: pipeline)

      visit project_merge_request_path(project, merge_request)
    end

    it 'has confirm button when MWBS button' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests
      expect(page).to have_selector('.accept-merge-request.btn-confirm')
    end
  end

  context 'view merge request where there is no pipeline yet' do
    before do
      pipeline = create(
        :ci_pipeline,
        project: project,
        sha: merge_request.diff_head_sha,
        ref: merge_request.source_branch
      )
      create(:ci_build, pipeline: pipeline)

      visit project_merge_request_path(project, merge_request)
    end

    it 'has pipeline loading state' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      expect(page).to have_text("Checking pipeline status")
    end
  end

  context 'view merge request in project with only-mwps setting enabled but no CI is set up' do
    before do
      visit project_merge_request_path(project_only_mwps, merge_request_in_only_mwps_project)
    end

    it 'is not allowed to set auto merge' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      expect(page).to have_selector('.accept-merge-request')
    end
  end

  context 'view merge request with auto merge enabled but automatically merge fails' do
    before do
      merge_request.update!(
        auto_merge_enabled: true,
        auto_merge_strategy: AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS,
        merge_user: merge_request.author,
        merge_error: 'Something went wrong'
      )

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows information about the merge error' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      page.within('.mr-state-widget') do
        expect(page).to have_content('Something went wrong.')
      end
    end
  end

  context 'view merge request with auto merge enabled but automatically merge fails' do
    before do
      merge_request.update!(
        merge_when_pipeline_succeeds: true,
        merge_user: merge_request.author,
        merge_error: 'Something went wrong'
      )

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows information about the merge error' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      page.within('.mr-state-widget') do
        expect(page).to have_content('Something went wrong.')
      end
    end
  end

  context 'view merge request where fast-forward merge is not possible' do
    before do
      project.update!(merge_requests_ff_only_enabled: true)

      merge_request.update!(
        merge_user: merge_request.author,
        merge_status: :cannot_be_merged
      )

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows information about the merge error' do
      # Wait for the `ci_status` and `merge_check` requests
      wait_for_requests

      click_button 'Expand merge checks'

      expect(page).to have_content('Merge request must be rebased, because a fast-forward merge is not possible.')
    end
  end

  context 'merge error' do
    before do
      allow_any_instance_of(Repository).to receive(:merge).and_return(false)
      visit project_merge_request_path(project, merge_request)
    end

    it 'updates the MR widget', :sidekiq_might_not_need_inline, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/449626' do
      page.within('.mr-state-widget') do
        click_button 'Merge'
      end

      expect(page).to have_content('An error occurred while merging')
    end
  end

  context 'user can merge into target project but cannot push to fork', :js do
    let(:forked_project) { fork_project(project, nil, repository: true) }
    let(:user2) { create(:user) }

    before do
      project.add_maintainer(user2)
      sign_out(:user)
      sign_in(user2)
      merge_request.update!(source_project: forked_project)
      visit project_merge_request_path(project, merge_request)
    end

    it 'user can merge into the target project', :sidekiq_inline do
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
      merge_request.update!(
        source_project: forked_project,
        target_project: project,
        merge_params: { 'force_remove_source_branch' => '1' }
      )
      visit project_merge_request_path(project, merge_request)
    end

    it 'user cannot remove source branch', :sidekiq_might_not_need_inline do
      expect(page).not_to have_field('remove-source-branch-input')
    end
  end

  context 'ongoing merge process' do
    it 'shows Merging state' do
      allow_any_instance_of(MergeRequest).to receive(:merge_ongoing?).and_return(true)

      visit project_merge_request_path(project, merge_request)

      wait_for_requests

      expect(page).not_to have_button('Merge', exact: true)
      expect(page).to have_content('Merging!')
    end
  end

  context 'exposed artifacts' do
    subject { visit project_merge_request_path(project, merge_request) }

    context 'when merge request has exposed artifacts' do
      let(:merge_request) { create(:merge_request, :with_exposed_artifacts, source_project: project) }
      let(:job) { merge_request.head_pipeline.builds.last }
      let!(:artifacts_metadata) { create(:ci_job_artifact, :metadata, job: job) }

      context 'when result has not been parsed yet' do
        it 'shows parsing status' do
          subject

          expect(page).to have_content('Loading artifacts')
        end
      end

      context 'when result has been parsed' do
        before do
          allow_any_instance_of(MergeRequest).to receive(:find_exposed_artifacts).and_return(
            status: :parsed, data: [
              {
                text: "the artifact",
                url: "/namespace1/project1/-/jobs/1/artifacts/file/ci_artifacts.txt",
                job_path: "/namespace1/project1/-/jobs/1",
                job_name: "test"
              }
            ])
        end

        it 'shows the parsed results' do
          subject

          expect(page).to have_content('View exposed artifact')
        end
      end
    end

    context 'when merge request does not have exposed artifacts' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it 'does not show parsing status' do
        subject

        expect(page).not_to have_content('Loading artifacts')
      end
    end
  end

  context 'when merge request has test reports' do
    let!(:head_pipeline) do
      create(
        :ci_pipeline,
        :success,
        project: project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha
      )
    end

    let!(:build) { create(:ci_build, :success, pipeline: head_pipeline, project: project) }

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when result has not been parsed yet' do
      let!(:job_artifact) { create(:ci_job_artifact, :junit, job: build, project: project) }

      before do
        visit project_merge_request_path(project, merge_request)
      end

      it 'shows parsing status' do
        expect(page).to have_content('Test summary results are being parsed')
      end
    end

    context 'when result has already been parsed' do
      context 'when JUnit xml is correctly formatted' do
        let!(:job_artifact) { create(:ci_job_artifact, :junit, job: build, project: project) }

        before do
          allow_any_instance_of(MergeRequest).to receive(:compare_test_reports).and_return(compared_data)

          visit project_merge_request_path(project, merge_request)
        end

        it 'shows parsed results' do
          expect(page).to have_content('Test summary:')
        end
      end

      context 'when JUnit xml is corrupted' do
        let!(:job_artifact) { create(:ci_job_artifact, :junit_with_corrupted_data, job: build, project: project) }

        before do
          allow_any_instance_of(MergeRequest).to receive(:compare_test_reports).and_return(compared_data)

          visit project_merge_request_path(project, merge_request)
        end

        it 'shows the error state' do
          expect(page).to have_content('Test summary failed to load results')
        end
      end

      def compared_data
        Ci::CompareTestReportsService.new(project).execute(nil, head_pipeline)
      end
    end

    context 'when test reports have been parsed correctly' do
      let(:serialized_data) do
        {
          status: :parsed,
          data: TestReportsComparerSerializer
            .new(project: project)
            .represent(comparer)
        }
      end

      before do
        stub_const("Gitlab::Ci::Reports::TestSuiteComparer::DEFAULT_MAX_TESTS", 2)
        stub_const("Gitlab::Ci::Reports::TestSuiteComparer::DEFAULT_MIN_TESTS", 1)

        allow_any_instance_of(MergeRequest)
          .to receive(:has_test_reports?).and_return(true)
        allow_any_instance_of(MergeRequest)
          .to receive(:compare_test_reports).and_return(serialized_data)

        visit project_merge_request_path(project, merge_request)
      end

      context 'when a new failures exists' do
        let(:base_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
            reports.get_suite('junit').add_test_case(create_test_case_java_success)
          end
        end

        let(:head_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
            reports.get_suite('junit').add_test_case(create_test_case_java_failed)
          end
        end

        it 'shows test reports summary which includes the new failure' do
          within_testid('widget-extension') do
            click_expand_button

            expect(page).to have_content('Test summary: 1 failed, 2 total tests')
            within_testid('widget-extension-collapsed-section') do
              expect(page).to have_content('rspec: no changed test results, 1 total test')
              expect(page).to have_content('junit: 1 failed, 1 total test')
              expect(page).to have_content('New')
              expect(page).to have_content('addTest')
            end
          end
        end

        context 'when user clicks the new failure' do
          it 'shows the test report detail' do
            within_testid('widget-extension') do
              click_expand_button

              within_testid('widget-extension-collapsed-section') do
                click_button 'View details'
              end
            end

            within_testid('test-case-details-modal') do
              expect(page).to have_content('addTest')
              expect(page).to have_content('6.66')
              expect(page).to have_content(sample_java_failed_message.gsub(/\s+/, ' ').strip)
            end
          end
        end
      end

      context 'when an existing failure exists' do
        let(:base_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_failed)
            reports.get_suite('junit').add_test_case(create_test_case_java_success)
          end
        end

        let(:head_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_failed)
            reports.get_suite('junit').add_test_case(create_test_case_java_success)
          end
        end

        it 'shows test reports summary which includes the existing failure' do
          within_testid('widget-extension') do
            click_expand_button

            expect(page).to have_content('Test summary: 1 failed, 2 total tests')
            within_testid('widget-extension-collapsed-section') do
              expect(page).to have_content('rspec: 1 failed, 1 total test')
              expect(page).to have_content('junit: no changed test results, 1 total test')
              expect(page).to have_content('Test#sum when a is 1 and b is 3 returns summary')
            end
          end
        end

        context 'when user clicks the existing failure' do
          it 'shows test report detail of it' do
            within_testid('widget-extension') do
              click_expand_button

              within_testid('widget-extension-collapsed-section') do
                click_button 'View details'
              end
            end

            within_testid('test-case-details-modal') do
              expect(page).to have_content('Test#sum when a is 1 and b is 3 returns summary')
              expect(page).to have_content('2.22')
              expect(page).to have_content(sample_rspec_failed_message.gsub(/\s+/, ' ').strip)
            end
          end
        end
      end

      context 'when a resolved failure exists' do
        let(:base_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
            reports.get_suite('junit').add_test_case(create_test_case_java_failed)
          end
        end

        let(:head_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
            reports.get_suite('junit').add_test_case(create_test_case_java_success)
          end
        end

        it 'shows test reports summary which includes the resolved failure' do
          within_testid('widget-extension') do
            click_expand_button

            expect(page).to have_content('Test summary: 1 fixed test result, 2 total tests')
            within_testid('widget-extension-collapsed-section') do
              expect(page).to have_content('rspec: no changed test results, 1 total test')
              expect(page).to have_content('junit: 1 fixed test result, 1 total test')
              expect(page).to have_content('Fixed')
              expect(page).to have_content('addTest')
            end
          end
        end

        context 'when user clicks the resolved failure' do
          it 'shows test report detail of it' do
            within_testid('widget-extension') do
              click_expand_button

              within_testid('widget-extension-collapsed-section') do
                click_button 'View details'
              end
            end

            within_testid('test-case-details-modal') do
              expect(page).to have_content('addTest')
              expect(page).to have_content('5.55')
            end
          end
        end
      end

      context 'when a new error exists' do
        let(:base_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
            reports.get_suite('junit').add_test_case(create_test_case_java_success)
          end
        end

        let(:head_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
            reports.get_suite('junit').add_test_case(create_test_case_java_error)
          end
        end

        it 'shows test reports summary which includes the new error' do
          within_testid('widget-extension') do
            click_expand_button

            expect(page).to have_content('Test summary: 1 error, 2 total tests')
            within_testid('widget-extension-collapsed-section') do
              expect(page).to have_content('rspec: no changed test results, 1 total test')
              expect(page).to have_content('junit: 1 error, 1 total test')
              expect(page).to have_content('New')
              expect(page).to have_content('addTest')
            end
          end
        end

        context 'when user clicks the new error' do
          it 'shows the test report detail' do
            within_testid('widget-extension') do
              click_expand_button

              within_testid('widget-extension-collapsed-section') do
                click_button 'View details'
              end
            end

            within_testid('test-case-details-modal') do
              expect(page).to have_content('addTest')
              expect(page).to have_content('8.88')
            end
          end
        end
      end

      context 'when an existing error exists' do
        let(:base_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_error)
            reports.get_suite('junit').add_test_case(create_test_case_java_success)
          end
        end

        let(:head_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_error)
            reports.get_suite('junit').add_test_case(create_test_case_java_success)
          end
        end

        it 'shows test reports summary which includes the existing error' do
          within_testid('widget-extension') do
            click_expand_button

            expect(page).to have_content('Test summary: 1 error, 2 total tests')
            within_testid('widget-extension-collapsed-section') do
              expect(page).to have_content('rspec: 1 error, 1 total test')
              expect(page).to have_content('junit: no changed test results, 1 total test')
              expect(page).to have_content('Test#sum when a is 4 and b is 4 returns summary')
            end
          end
        end

        context 'when user clicks the existing error' do
          it 'shows test report detail of it' do
            within_testid('widget-extension') do
              click_expand_button

              within_testid('widget-extension-collapsed-section') do
                click_button 'View details'
              end
            end

            within_testid('test-case-details-modal') do
              expect(page).to have_content('Test#sum when a is 4 and b is 4 returns summary')
              expect(page).to have_content('4.44')
            end
          end
        end
      end

      context 'when a resolved error exists' do
        let(:base_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
            reports.get_suite('junit').add_test_case(create_test_case_java_error)
          end
        end

        let(:head_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
            reports.get_suite('junit').add_test_case(create_test_case_java_success)
          end
        end

        it 'shows test reports summary which includes the resolved error' do
          within_testid('widget-extension') do
            click_expand_button

            expect(page).to have_content('Test summary: 1 fixed test result, 2 total tests')
            within_testid('widget-extension-collapsed-section') do
              expect(page).to have_content('rspec: no changed test results, 1 total test')
              expect(page).to have_content('junit: 1 fixed test result, 1 total test')
              expect(page).to have_content('Fixed')
              expect(page).to have_content('addTest')
            end
          end
        end

        context 'when user clicks the resolved error' do
          it 'shows test report detail of it' do
            within_testid('widget-extension') do
              click_expand_button

              within_testid('widget-extension-collapsed-section') do
                click_button 'View details'
              end
            end

            within_testid('test-case-details-modal') do
              expect(page).to have_content('addTest')
              expect(page).to have_content('5.55')
            end
          end
        end
      end

      context 'properly truncates the report' do
        let(:base_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            10.times do |index|
              reports.get_suite('rspec').add_test_case(
                create_test_case_rspec_failed(index))
              reports.get_suite('junit').add_test_case(
                create_test_case_java_success(index))
            end
          end
        end

        let(:head_reports) do
          Gitlab::Ci::Reports::TestReport.new.tap do |reports|
            10.times do |index|
              reports.get_suite('rspec').add_test_case(
                create_test_case_rspec_failed(index))
              reports.get_suite('junit').add_test_case(
                create_test_case_java_failed(index))
            end
          end
        end

        it 'shows test reports summary which includes the resolved failure' do
          within_testid('widget-extension') do
            click_expand_button

            expect(page).to have_content('Test summary: 20 failed, 20 total tests')
            within_testid('widget-extension-collapsed-section') do
              expect(page).to have_content('rspec: 10 failed, 10 total tests')
              expect(page).to have_content('junit: 10 failed, 10 total tests')

              expect(page).to have_content('Test#sum when a is 1 and b is 3 returns summary', count: 2)
            end
          end
        end
      end

      def comparer
        Gitlab::Ci::Reports::TestReportsComparer.new(base_reports, head_reports)
      end
    end
  end

  context 'when MR has pipeline but user does not have permission' do
    let(:sha) { project.commit(merge_request.source_branch).sha }
    let!(:pipeline) { create(:ci_pipeline, status: 'success', sha: sha, project: project, ref: merge_request.source_branch) }

    before do
      project.update!(
        visibility_level: Gitlab::VisibilityLevel::PUBLIC,
        public_builds: false
      )
      merge_request.update!(head_pipeline: pipeline)
      sign_out(:user)

      visit project_merge_request_path(project, merge_request)
    end

    it 'renders a CI pipeline loading state' do
      within '.ci-widget' do
        expect(page).to have_content('Checking pipeline status')
      end
    end
  end

  context 'views MR when pipeline has code coverage enabled' do
    let!(:pipeline) { create(:ci_pipeline, status: 'success', project: project, ref: merge_request.source_branch) }
    let!(:build) { create(:ci_build, :success, :coverage, pipeline: pipeline) }

    before do
      merge_request.update!(head_pipeline: pipeline)

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows the coverage' do
      within '.ci-widget' do
        expect(find_by_testid('pipeline-coverage')).to have_content('Test coverage 99.90% ')
      end
    end
  end
end
