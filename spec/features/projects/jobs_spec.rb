# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Jobs', :clean_gitlab_redis_shared_state, feature_category: :groups_and_projects do
  include Gitlab::Routing
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:user_access_level) { :developer }
  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha) }

  let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }
  let(:job2) { create(:ci_build) }

  let(:artifacts_file) do
    fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif')
  end

  before do
    project.add_role(user, user_access_level)
    sign_in(user)
  end

  describe "GET /:project/jobs" do
    context 'with no jobs' do
      before do
        visit project_jobs_path(project)

        wait_for_requests
      end

      it 'shows the empty state page', :js do
        expect(page).to have_content('Use jobs to automate your tasks')
        expect(page).to have_link('Create CI/CD configuration file', href: project_ci_pipeline_editor_path(project))
      end
    end

    context 'with a job' do
      let!(:job) { create(:ci_build, pipeline: pipeline) }

      context "when visiting old URL" do
        let(:jobs_url) do
          project_jobs_path(project)
        end

        before do
          visit jobs_url.sub('/-/jobs', '/builds')
        end

        it "redirects to new URL" do
          expect(page).to have_current_path(jobs_url, ignore_query: true)
        end
      end
    end
  end

  describe "GET /:project/jobs/:id" do
    context "Job from project" do
      let(:job) { create(:ci_build, :success, :trace_live, pipeline: pipeline) }

      it 'shows status name', :js do
        visit project_job_path(project, job)

        wait_for_requests

        expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Passed')
      end

      it 'shows commit`s data', :js do
        requests = inspect_requests do
          visit project_job_path(project, job)
        end

        wait_for_requests
        expect(requests.first.status_code).to eq(200)
        expect(page).to have_content pipeline.sha[0..7]
        expect(page).to have_content pipeline.commit.title
      end

      it 'shows active job', :js do
        visit project_job_path(project, job)

        wait_for_requests
        expect(page).to have_selector('[data-testid="active-job"]')
      end
    end

    context 'pipeline info block', :js do
      it 'shows pipeline id and source branch' do
        visit project_job_path(project, job)

        within '.js-pipeline-info' do
          expect(page).to have_content("Pipeline ##{pipeline.id} Pending for #{pipeline.ref}")
        end
      end

      context 'when pipeline is detached merge request pipeline' do
        let(:merge_request) do
          create(:merge_request,
            :with_detached_merge_request_pipeline,
            target_project: target_project,
            source_project: source_project)
        end

        let(:source_project) { project }
        let(:target_project) { project }
        let(:pipeline) { merge_request.all_pipelines.last }
        let(:job) { create(:ci_build, pipeline: pipeline) }

        it 'shows merge request iid and source branch' do
          visit project_job_path(project, job)

          within '.js-pipeline-info' do
            expect(page).to have_content("for !#{pipeline.merge_request.iid} " \
                                         "with #{pipeline.merge_request.source_branch}")
            expect(page).to have_link("!#{pipeline.merge_request.iid}",
              href: project_merge_request_path(project, merge_request))
            expect(page).to have_link(pipeline.merge_request.source_branch,
              href: project_commits_path(project, merge_request.source_branch))
          end
        end

        context 'when source project is a forked project' do
          let(:source_project) { fork_project(project, user, repository: true) }
          let(:target_project) { project }

          it 'shows merge request iid and source branch', :sidekiq_might_not_need_inline do
            visit project_job_path(source_project, job)

            within '.js-pipeline-info' do
              expect(page).to have_content("for !#{pipeline.merge_request.iid} " \
                                           "with #{pipeline.merge_request.source_branch}")
              expect(page).to have_link("!#{pipeline.merge_request.iid}",
                href: project_merge_request_path(project, merge_request))
              expect(page).to have_link(pipeline.merge_request.source_branch,
                href: project_commits_path(source_project, merge_request.source_branch))
            end
          end
        end
      end

      context 'when pipeline is merge request pipeline' do
        let(:merge_request) do
          create(:merge_request,
            :with_merge_request_pipeline,
            target_project: target_project,
            source_project: source_project)
        end

        let(:source_project) { project }
        let(:target_project) { project }
        let(:pipeline) { merge_request.all_pipelines.last }
        let(:job) { create(:ci_build, pipeline: pipeline) }

        it 'shows merge request iid and source branch' do
          visit project_job_path(project, job)

          within '.js-pipeline-info' do
            expect(page).to have_content("for !#{pipeline.merge_request.iid} " \
                                         "with #{pipeline.merge_request.source_branch} " \
                                         "into #{pipeline.merge_request.target_branch}")
            expect(page).to have_link("!#{pipeline.merge_request.iid}",
              href: project_merge_request_path(project, merge_request))
            expect(page).to have_link(pipeline.merge_request.source_branch,
              href: project_commits_path(project, merge_request.source_branch))
            expect(page).to have_link(pipeline.merge_request.target_branch,
              href: project_commits_path(project, merge_request.target_branch))
          end
        end

        context 'when source project is a forked project' do
          let(:source_project) { fork_project(project, user, repository: true) }
          let(:target_project) { project }

          it 'shows merge request iid and source branch', :sidekiq_might_not_need_inline do
            visit project_job_path(source_project, job)

            within '.js-pipeline-info' do
              expect(page).to have_content("for !#{pipeline.merge_request.iid} " \
                                           "with #{pipeline.merge_request.source_branch} " \
                                           "into #{pipeline.merge_request.target_branch}")
              expect(page).to have_link("!#{pipeline.merge_request.iid}",
                href: project_merge_request_path(project, merge_request))
              expect(page).to have_link(pipeline.merge_request.source_branch,
                href: project_commits_path(source_project, merge_request.source_branch))
              expect(page).to have_link(pipeline.merge_request.target_branch,
                href: project_commits_path(project, merge_request.target_branch))
            end
          end
        end
      end
    end

    context 'sidebar', :js do
      let(:job) { create(:ci_build, :success, :trace_live, pipeline: pipeline, name: '<img src=x onerror=alert(document.domain)>') }

      before do
        visit project_job_path(project, job)
        wait_for_requests
      end

      it 'renders escaped tooltip name' do
        find_by_testid('active-job').hover
        expect(page).to have_content('<img src=x onerror=alert(document.domain)> - passed')
      end
    end

    context 'when job is not running', :js do
      let(:job) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
      end

      context 'if job passed' do
        it 'does not show New issue button' do
          expect(page).not_to have_link('New issue')
        end
      end

      context 'if job failed' do
        let(:job) { create(:ci_build, :failed, :trace_artifact, pipeline: pipeline) }

        before do
          visit project_job_path(project, job)
        end

        it 'shows New issue button' do
          expect(page).to have_link('New issue')
        end

        it 'links to issues/new with the title and description filled in' do
          button_title = "Job Failed ##{job.id}"
          job_url = project_job_url(project, job, host: page.server.host, port: page.server.port)
          options = { issue: { title: button_title, description: "Job [##{job.id}](#{job_url}) failed for #{job.sha}:\n" } }

          href = new_project_issue_path(project, options)

          page.within(find_by_testid('job-sidebar')) do
            expect(find_by_testid('job-new-issue')['href']).to include(href)
          end
        end
      end
    end

    context 'when job is running', :js do
      let(:job) { create(:ci_build, :running, pipeline: pipeline) }
      let(:job_url) { project_job_path(project, job) }

      before do
        visit job_url
        wait_for_requests
      end

      context 'job is cancelable' do
        it 'shows cancel button' do
          find_by_testid('cancel-button').click

          expect(page).to have_current_path(job_url, ignore_query: true)
        end
      end
    end

    context 'when job is waiting for resource', :js do
      let(:job) { create(:ci_build, :waiting_for_resource, pipeline: pipeline, resource_group: resource_group) }
      let(:resource_group) { create(:ci_resource_group, project: project) }

      before do
        resource_group.assign_resource_to(create(:ci_build))

        visit project_job_path(project, job)
        wait_for_requests
      end

      it 'shows correct UI components' do
        expect(page).to have_content("This job is waiting for resource: #{resource_group.key}")
        expect(page).to have_link("View job currently using resource")
      end
    end

    context "Job from other project" do
      before do
        visit project_job_path(project, job2)
      end

      it { expect(page.status_code).to eq(404) }
    end

    context "Download artifacts", :js do
      before do
        create(:ci_job_artifact, :archive, file: artifacts_file, job: job)
        visit project_job_path(project, job)
      end

      it 'has button to download artifacts' do
        expect(page).to have_content 'Download'
      end

      it 'downloads the zip file when user clicks the download button' do
        requests = inspect_requests do
          click_link 'Download'
        end

        artifact_request = requests.find { |req| req.url.include?('artifacts/download') }

        expect(artifact_request.response_headers['Content-Disposition']).to eq(%(attachment; filename="#{job.artifacts_file.filename}"; filename*=UTF-8''#{job.artifacts_file.filename}))
        expect(artifact_request.response_headers['Content-Transfer-Encoding']).to eq("binary")
        expect(artifact_request.response_headers['Content-Type']).to eq("image/gif")
        expect(artifact_request.body).to eq(job.artifacts_file.file.read.b)
      end
    end

    context 'Artifacts expire date', :js do
      before do
        create(:ci_job_artifact, :archive, file: artifacts_file, expire_at: expire_at, job: job)
        job.update!(artifacts_expire_at: expire_at)

        visit project_job_path(project, job)
      end

      context 'no expire date defined' do
        let(:expire_at) { nil }

        it 'does not have the Keep button' do
          expect(page).not_to have_content 'Keep'
        end
      end

      context 'when expire date is defined' do
        let(:expire_at) { Time.zone.now + 7.days }

        context 'when user has ability to update job' do
          context 'when artifacts are unlocked' do
            before do
              job.pipeline.unlocked!
            end

            it 'keeps artifacts when keep button is clicked' do
              expect(page).to have_content 'The artifacts will be removed in'

              click_link 'Keep'

              expect(page).to have_no_link 'Keep'
              expect(page).to have_no_content 'The artifacts will be removed in'
            end
          end

          context 'when artifacts are locked' do
            before do
              job.pipeline.artifacts_locked!
            end

            it 'shows the keep button' do
              expect(page).to have_link 'Keep'
            end
          end
        end

        context 'when user does not have ability to update job' do
          let(:user_access_level) { :guest }

          it 'does not have keep button' do
            expect(page).to have_no_link 'Keep'
          end
        end
      end

      context 'when artifacts expired' do
        let(:expire_at) { Time.zone.now - 7.days }

        context 'when artifacts are unlocked' do
          before do
            job.pipeline.unlocked!
          end

          it 'does not have the Keep button' do
            expect(page).to have_content 'The artifacts were removed'
            expect(page).not_to have_link 'Keep'
          end
        end

        context 'when artifacts are locked' do
          before do
            job.pipeline.artifacts_locked!
          end

          it 'has the Keep button' do
            expect(page).not_to have_content 'The artifacts were removed'
            expect(page).to have_link 'Keep'
          end
        end
      end
    end

    context "when visiting old URL" do
      let(:job_url) do
        project_job_path(project, job)
      end

      before do
        visit job_url.sub('/-/jobs', '/builds')
      end

      it "redirects to new URL" do
        expect(page).to have_current_path(job_url, ignore_query: true)
      end
    end

    describe 'Raw trace', :js do
      before do
        job.run!

        visit project_job_path(project, job)
      end

      it do
        wait_for_all_requests
        expect(page).to have_css('[data-testid="job-raw-link-controller"]')
      end
    end

    describe 'HTML trace', :js do
      before do
        job.run!

        visit project_job_path(project, job)
      end

      context 'when job has an initial trace' do
        it 'loads job logs' do
          expect(page).to have_content 'BUILD TRACE'

          job.trace.write(+'a+b') do |stream|
            stream.append(+' and more trace', 11)
          end

          expect(page).to have_content 'BUILD TRACE and more trace'
        end
      end
    end

    describe 'Variables' do
      let(:trigger_request) { create(:ci_trigger_request, project_id: project.id) }
      let(:job) { create(:ci_build, pipeline: pipeline, trigger_request: trigger_request) }

      context 'when user is a maintainer' do
        shared_examples 'no reveal button variables behavior' do
          it 'renders a hidden value with no reveal values button', :js do
            expect(page).to have_content('Trigger token')
            expect(page).to have_content('Trigger variables')

            expect(page).not_to have_selector('[data-testid="trigger-reveal-values-button"]')

            expect(page).to have_selector('[data-testid="trigger-build-key"]', text: 'TRIGGER_KEY_1')
            expect(page).to have_selector('[data-testid="trigger-build-value"]', text: '••••••')
          end
        end

        context 'when variables are stored in trigger_request' do
          before do
            trigger_request.update_attribute(:variables, { 'TRIGGER_KEY_1' => 'TRIGGER_VALUE_1' })

            visit project_job_path(project, job)
          end

          it_behaves_like 'no reveal button variables behavior'
        end

        context 'when variables are stored in pipeline_variables' do
          before do
            create(:ci_pipeline_variable, pipeline: pipeline, key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1')

            visit project_job_path(project, job)
          end

          it_behaves_like 'no reveal button variables behavior'
        end
      end

      context 'when user is a maintainer' do
        before do
          project.add_maintainer(user)
        end

        shared_examples 'reveal button variables behavior' do
          it 'renders a hidden value with a reveal values button', :js do
            expect(page).to have_content('Trigger token')
            expect(page).to have_content('Trigger variables')

            expect(page).to have_selector('[data-testid="trigger-reveal-values-button"]')

            expect(page).to have_selector('[data-testid="trigger-build-key"]', text: 'TRIGGER_KEY_1')
            expect(page).to have_selector('[data-testid="trigger-build-value"]', text: '••••••')
          end

          it 'reveals values on button click', :js do
            click_button 'Reveal values'

            expect(page).to have_selector('[data-testid="trigger-build-key"]', text: 'TRIGGER_KEY_1')
            expect(page).to have_selector('[data-testid="trigger-build-value"]', text: 'TRIGGER_VALUE_1')
          end
        end

        context 'when variables are stored in trigger_request' do
          before do
            trigger_request.update_attribute(:variables, { 'TRIGGER_KEY_1' => 'TRIGGER_VALUE_1' })

            visit project_job_path(project, job)
          end

          it_behaves_like 'reveal button variables behavior'
        end

        context 'when variables are stored in pipeline_variables' do
          before do
            create(:ci_pipeline_variable, pipeline: pipeline, key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1')

            visit project_job_path(project, job)
          end

          it_behaves_like 'reveal button variables behavior'
        end
      end
    end

    context 'when job starts environment', :js do
      let(:environment) { create(:environment, name: 'production', project: project) }

      before do
        visit project_job_path(project, build)
        wait_for_requests
      end

      context 'job is successful and has deployment' do
        let(:build) { create(:ci_build, :success, :trace_live, environment: environment.name, pipeline: pipeline, deployment: deployment) }
        let(:deployment) { create(:deployment, :success, environment: environment, project: environment.project) }

        it 'shows a link for the job' do
          expect(page).to have_link environment.name
        end

        it 'shows deployment message' do
          expect(page).to have_content 'This job is deployed to production'
          expect(find_by_testid('job-environment-link')['href']).to match("environments/#{environment.id}")
        end

        context 'when there is a cluster used for the deployment' do
          let(:deployment) { create(:deployment, :success, :on_cluster, environment: environment) }
          let(:user_access_level) { :maintainer }
          let(:cluster) { deployment.cluster }

          it 'shows a link to the cluster' do
            expect(page).to have_link cluster.name
          end

          it 'shows the name of the cluster' do
            expect(page).to have_content "using cluster #{cluster.name}"
          end

          context 'when the user is not able to view the cluster' do
            let(:user_access_level) { :reporter }

            it 'includes only the name of the cluster without a link' do
              expect(page).to have_content "using cluster #{cluster.name}"
              expect(page).not_to have_link cluster.name
            end
          end
        end
      end

      context 'job is complete and not successful' do
        let(:build) { create(:ci_build, :failed, :trace_artifact, environment: environment.name, pipeline: pipeline) }

        it 'shows a link for the job' do
          expect(page).to have_link environment.name
          expect(find_by_testid('job-environment-link')['href']).to match("environments/#{environment.id}")
        end
      end

      context 'deployment still not finished' do
        let(:build) { create(:ci_build, :running, environment: environment.name, pipeline: pipeline) }

        it 'shows a link to latest deployment' do
          expect(page).to have_link environment.name
          expect(page).to have_content 'This job is creating a deployment'
          expect(find_by_testid('job-environment-link')['href']).to match("environments/#{environment.id}")
        end
      end
    end

    context 'when job stops environment', :js do
      let(:environment) { create(:environment, name: 'production', project: project) }
      let(:build) do
        create(
          :ci_build,
          :success,
          :trace_live,
          environment: environment.name,
          pipeline: pipeline,
          options: { environment: { action: 'stop' } }
        )
      end

      before do
        visit project_job_path(project, build)
        wait_for_requests
      end

      it 'does not show environment information banner' do
        expect(page).not_to have_selector('[data-testid="jobs-environment-container"]')
        expect(page).not_to have_selector('[data-testid="jobs-environment-info"]')
        expect(page).not_to have_text(environment.name)
      end
    end

    describe 'environment info in job view', :js do
      before do
        allow_any_instance_of(Ci::Build).to receive(:create_deployment)

        visit project_job_path(project, job)
        wait_for_requests
      end

      context 'job with outdated deployment' do
        let(:job) { create(:ci_build, :success, :trace_artifact, environment: 'staging', pipeline: pipeline) }
        let(:second_build) { create(:ci_build, :success, :trace_artifact, environment: 'staging', pipeline: pipeline) }
        let(:environment) { create(:environment, name: 'staging', project: project) }
        let!(:first_deployment) { create(:deployment, :success, environment: environment, deployable: job) }
        let!(:second_deployment) { create(:deployment, :success, environment: environment, deployable: second_build) }

        it 'shows deployment message' do
          expected_text = 'This job is an out-of-date deployment to staging. View the most recent deployment.'

          expect(page).to have_css('[data-testid="jobs-environment-info"]', text: expected_text)
        end

        it 'renders a link to the most recent deployment' do
          expect(find_by_testid('job-environment-link')['href']).to match("environments/#{environment.id}")
          expect(find_by_testid('job-deployment-link')['href']).to include(second_deployment.deployable.project.path, second_deployment.deployable_id.to_s)
        end

        context 'when deployment does not have a deployable' do
          let!(:second_deployment) { create(:deployment, :success, environment: environment, deployable: nil) }

          it 'has an empty href' do
            expect(find_by_testid('job-deployment-link')['href']).to be_empty
          end
        end
      end

      context 'job failed to deploy' do
        let(:job) { create(:ci_build, :failed, :trace_artifact, environment: 'staging', pipeline: pipeline) }
        let!(:environment) { create(:environment, name: 'staging', project: project) }

        it 'shows deployment message' do
          expected_text = 'The deployment of this job to staging did not succeed.'

          expect(page).to have_css('[data-testid="jobs-environment-info"]', text: expected_text)
        end
      end

      context 'job will deploy' do
        let(:job) { create(:ci_build, :running, :trace_live, environment: 'staging', pipeline: pipeline) }

        context 'when environment exists' do
          let!(:environment) { create(:environment, name: 'staging', project: project) }

          it 'shows deployment message' do
            expected_text = 'This job is creating a deployment to staging'

            expect(page).to have_css('[data-testid="jobs-environment-info"]', text: expected_text)
            expect(find_by_testid('job-environment-link')['href']).to match("environments/#{environment.id}")
          end

          context 'when it has deployment' do
            let!(:deployment) { create(:deployment, :success, environment: environment) }

            it 'shows that deployment will be overwritten' do
              expected_text = 'This job is creating a deployment to staging'

              expect(page).to have_css('[data-testid="jobs-environment-info"]', text: expected_text)
              expect(page).to have_css('[data-testid="jobs-environment-info"]', text: 'latest deployment')
              expect(find_by_testid('job-environment-link')['href']).to match("environments/#{environment.id}")
            end
          end
        end

        context 'when environment does not exist' do
          let!(:environment) { create(:environment, name: 'staging', project: project) }

          it 'shows deployment message' do
            expected_text = 'This job is creating a deployment to staging'

            expect(page).to have_css(
              '[data-testid="jobs-environment-info"]', text: expected_text)
            expect(page).not_to have_css(
              '[data-testid="jobs-environment-info"]', text: 'latest deployment')
            expect(find_by_testid('job-environment-link')['href']).to match("environments/#{environment.id}")
          end
        end
      end

      context 'job that failed to deploy and environment has not been created' do
        let(:job) { create(:ci_build, :failed, :trace_artifact, environment: 'staging', pipeline: pipeline) }
        let!(:environment) { create(:environment, name: 'staging', project: project) }

        it 'shows deployment message' do
          expected_text = 'The deployment of this job to staging did not succeed'

          expect(page).to have_css(
            '[data-testid="jobs-environment-info"]', text: expected_text)
        end
      end

      context 'job that will deploy and environment has not been created' do
        let(:job) { create(:ci_build, :running, :trace_live, environment: 'staging', pipeline: pipeline) }
        let!(:environment) { create(:environment, name: 'staging', project: project) }

        it 'shows deployment message' do
          expected_text = 'This job is creating a deployment to staging'

          expect(page).to have_css(
            '[data-testid="jobs-environment-info"]', text: expected_text)
          expect(page).not_to have_css(
            '[data-testid="jobs-environment-info"]', text: 'latest deployment')
        end
      end
    end

    context 'Playable manual action' do
      let(:job) { create(:ci_build, :playable, pipeline: pipeline) }

      before do
        project.add_developer(user)
        visit project_job_path(project, job)
      end

      it 'shows manual action empty state', :js do
        expect(page).to have_content(job.detailed_status(user).illustration[:title])
        expect(page).to have_content('This job requires a manual action')
        expect(page).to have_content(
          _(
            'This job does not start automatically and must be started manually. ' \
            'You can add CI/CD variables below for last-minute configuration changes before starting the job.'
          )
        )
        expect(page).to have_button('Run job')
      end

      it 'plays manual action and shows pending status', :js do
        click_button 'Run job'

        wait_for_requests
        expect(page).to have_content('This job has not started yet')
        expect(page).to have_content('This job is in pending state and is waiting to be picked by a runner')
        expect(page).to have_content('pending')
      end
    end

    context 'Delayed job' do
      let(:job) { create(:ci_build, :scheduled, pipeline: pipeline) }

      before do
        project.add_developer(user)
        visit project_job_path(project, job)
      end

      it 'shows delayed job', :js do
        expect(page).to have_content('This is a delayed job to run in')
        expect(page).to have_content("This job will automatically run after its timer finishes.")
        expect(page).to have_link('Unschedule job')
      end

      it 'unschedules delayed job and shows manual action', :js do
        click_link 'Unschedule job'

        wait_for_requests
        expect(page).to have_content('This job requires a manual action')
        expect(page).to have_content(
          _(
            'This job does not start automatically and must be started manually. ' \
            'You can add CI/CD variables below for last-minute configuration changes before starting the job.'
          )
        )
        expect(page).to have_button('Run job')
      end
    end

    context 'Non triggered job' do
      let(:job) { create(:ci_build, :created, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
      end

      it 'shows empty state', :js do
        expect(page).to have_content(job.detailed_status(user).illustration[:title])
        expect(page).to have_content('This job has not been triggered yet')
        expect(page).to have_content('This job depends on upstream jobs that need to succeed in order for this job to be triggered')
      end
    end

    context 'Pending job', :js do
      let(:job) { create(:ci_build, :pending, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
      end

      it 'shows pending empty state' do
        expect(page).to have_content(job.detailed_status(user).illustration[:title])
        expect(page).to have_content('This job has not started yet')
        expect(page).to have_content('This job is in pending state and is waiting to be picked by a runner')
      end
    end

    context 'Canceled job', :js do
      context 'with log' do
        let(:job) { create(:ci_build, :canceled, :trace_artifact, pipeline: pipeline) }

        before do
          visit project_job_path(project, job)
        end

        it 'renders job log' do
          wait_for_all_requests
          expect(page).to have_selector('.job-log')
        end
      end

      context 'without log', :js do
        let(:job) { create(:ci_build, :canceled, pipeline: pipeline) }

        before do
          visit project_job_path(project, job)
        end

        it 'renders empty state' do
          expect(page).to have_content(job.detailed_status(user).illustration[:title])
          expect(page).not_to have_selector('.job-log')
          expect(page).to have_content('This job has been canceled')
        end
      end
    end

    context 'Skipped job', :js do
      let(:job) { create(:ci_build, :skipped, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
      end

      it 'renders empty state' do
        expect(page).to have_content(job.detailed_status(user).illustration[:title])
        expect(page).not_to have_selector('.job-log')
        expect(page).to have_content('This job has been skipped')
      end
    end

    context 'when job is failed but has no trace', :js do
      let(:job) { create(:ci_build, :failed, pipeline: pipeline) }

      it 'renders empty state' do
        visit project_job_path(project, job)

        expect(job).not_to have_trace
        expect(page).to have_content('This job does not have a trace.')
      end
    end

    context 'with erased job', :js do
      let(:job) { create(:ci_build, :erased, pipeline: pipeline) }

      it 'renders erased job warning' do
        visit project_job_path(project, job)
        wait_for_requests

        within_testid('job-erased-block') do
          expect(page).to have_content('Job has been erased')
        end
      end
    end

    context 'without erased job', :js do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'does not render erased job warning' do
        visit project_job_path(project, job)
        wait_for_requests

        expect(page).not_to have_css('[data-testid="job-erased-block"]')
      end
    end

    context 'on mobile', :js do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'renders collapsed sidebar' do
        page.current_window.resize_to(600, 800)

        visit project_job_path(project, job)
        wait_for_requests

        expect(page).to have_css('[data-testid="job-sidebar"].right-sidebar-collapsed', visible: false)
        expect(page).not_to have_css('[data-testid="job-sidebar"].right-sidebar-expanded', visible: false)
      end
    end

    context 'on desktop', :js do
      let(:job) { create(:ci_build, pipeline: pipeline) }

      it 'renders expanded sidebar' do
        visit project_job_path(project, job)
        wait_for_requests

        expect(page).to have_css('[data-testid="job-sidebar"].right-sidebar-expanded')
        expect(page).not_to have_css('[data-testid="job-sidebar"].right-sidebar-collapsed')
      end
    end

    context 'stuck', :js do
      before do
        visit project_job_path(project, job)
        wait_for_requests
      end

      context 'without active runners available' do
        let(:runner) { create(:ci_runner, :instance, :paused) }
        let(:job) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

        it 'renders message about job being stuck because no runners are active' do
          expect(page).to have_selector('[data-testid="job-stuck-no-active-runners"]')
          expect(page).to have_content("This job is stuck because you don't have any active runners that can run this job.")
        end
      end

      context 'when available runners can not run specified tag' do
        let(:runner) { create(:ci_runner, :instance, :paused) }
        let(:job) { create(:ci_build, :pending, pipeline: pipeline, runner: runner, tag_list: %w[docker linux]) }

        it 'renders message about job being stuck because of no runners with the specified tags' do
          expect(page).to have_selector('[data-testid="job-stuck-with-tags"')
          expect(page).to have_content("This job is stuck because of one of the following problems. There are no active runners online, no runners for the ")
          expect(page).to have_content("protected branch")
          expect(page).to have_content(", or no runners that match all of the job's tags:")
        end
      end

      context 'when runners are offline and build has tags' do
        let(:runner) { create(:ci_runner, :instance) }
        let(:job) { create(:ci_build, :pending, pipeline: pipeline, runner: runner, tag_list: %w[docker linux]) }

        it 'renders message about job being stuck because of no runners with the specified tags' do
          expect(page).to have_selector('[data-testid="job-stuck-with-tags"')
          expect(page).to have_content("This job is stuck because of one of the following problems. There are no active runners online, no runners for the ")
          expect(page).to have_content("protected branch")
          expect(page).to have_content(", or no runners that match all of the job's tags:")
        end
      end

      context 'without any runners available' do
        let(:job) { create(:ci_build, :pending, pipeline: pipeline) }

        it 'renders message about job being stuck because no runners are available' do
          expect(page).to have_selector('[data-testid="job-stuck-no-active-runners"]')
          expect(page).to have_content("This job is stuck because you don't have any active runners that can run this job.")
        end
      end

      context 'without available runners online' do
        let(:runner) { create(:ci_runner, :instance) }
        let(:job) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

        it 'renders message about job being stuck because runners are offline' do
          expect(page).to have_selector('[data-testid="job-stuck-no-runners"')
          expect(page).to have_content("This job is stuck because the project doesn't have any runners online assigned to it.")
        end
      end
    end
  end

  describe "POST /:project/jobs/:id/cancel", :js do
    context "Job from project" do
      before do
        job.run!
        visit project_job_path(project, job)
        find_by_testid('cancel-button').click
      end

      it 'loads the page and shows all needed controls' do
        expect(page).to have_selector('[data-testid="retry-button"')
      end
    end
  end

  describe "POST /:project/jobs/:id/retry", :js do
    context "Job from project", :js do
      before do
        job.run!
        job.cancel!
        visit project_job_path(project, job)
        wait_for_requests

        find_by_testid('retry-button').click
      end

      it 'shows the right status and buttons' do
        page.within('aside.right-sidebar') do
          expect(page).to have_selector('[data-testid="cancel-button"')
        end
      end
    end

    context "Job that current user is not allowed to retry" do
      before do
        job.run!
        job.cancel!
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

        sign_out(:user)
        sign_in(create(:user))
        visit project_job_path(project, job)
      end

      it 'does not show the Retry button' do
        page.within('aside.right-sidebar') do
          expect(page).not_to have_content 'Retry'
        end
      end
    end

    context "Job that failed because of a forward deployment failure" do
      let(:job) { create(:ci_build, :forward_deployment_failure, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
        wait_for_requests

        find_by_testid('retry-button').click
      end

      it 'shows a modal to warn the user' do
        page.within('.modal-header') do
          expect(page).to have_content 'Are you sure you want to retry this job?'
        end
      end

      it 'retries the job' do
        find_by_testid('retry-button-modal').click

        within_testid 'job-header-content' do
          expect(page).to have_content('Pending')
        end
      end
    end
  end

  describe "GET /:project/jobs/:id/download", :js do
    before do
      create(:ci_job_artifact, :archive, file: artifacts_file, job: job)
      visit project_job_path(project, job)

      click_link 'Download'
    end

    context "Build from other project" do
      let(:other_job_download_path) { download_project_job_artifacts_path(project, job2) }

      before do
        create(:ci_job_artifact, :archive, file: artifacts_file, job: job2)
      end

      it 'receive 404 from download request', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391632' do
        requests = inspect_requests { visit other_job_download_path }

        request = requests.find { |request| request.url == other_job_download_path }

        expect(request).to be_present
        expect(request.status_code).to eq(404)
      end
    end
  end

  describe 'GET /:project/jobs/:id/raw', :js do
    context 'access source' do
      context 'job from project' do
        context 'when job is running' do
          before do
            job.run!
          end

          it 'sends the right headers' do
            requests = inspect_requests(inject_headers: { 'X-Sendfile-Type' => 'X-Sendfile' }) do
              visit raw_project_job_path(project, job)
            end

            expect(requests.first.status_code).to eq(200)
            expect(requests.first.response_headers['Content-Type']).to eq('text/plain; charset=utf-8')
            expect(requests.first.response_headers['X-Sendfile']).to eq(job.trace.send(:current_path))
          end
        end

        context 'when job is complete' do
          let(:job) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }

          it 'sends the right headers' do
            requests = inspect_requests(inject_headers: { 'X-Sendfile-Type' => 'X-Sendfile' }) do
              visit raw_project_job_path(project, job)
            end

            expect(requests.first.status_code).to eq(200)
            expect(requests.first.response_headers['Content-Type']).to eq('text/plain; charset=utf-8')
            expect(requests.first.response_headers['X-Sendfile']).to eq(job.job_artifacts_trace.file.path)
          end
        end
      end

      context 'job from other project' do
        before do
          job2.run!
        end

        it 'sends the right headers' do
          requests = inspect_requests(inject_headers: { 'X-Sendfile-Type' => 'X-Sendfile' }) do
            visit raw_project_job_path(project, job2)
          end
          expect(requests.first.status_code).to eq(404)
        end
      end
    end

    context "when visiting old URL" do
      let(:raw_job_url) do
        raw_project_job_path(project, job)
      end

      before do
        visit raw_job_url.sub('/-/jobs', '/builds')
      end

      it "redirects to new URL" do
        expect(page).to have_current_path(raw_job_url, ignore_query: true)
      end
    end
  end

  describe "GET /:project/jobs/:id/trace.json" do
    let(:build) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

    context "Job from project" do
      before do
        visit trace_project_job_path(project, build, format: :json)
      end

      it { expect(page.status_code).to eq(200) }
    end

    context "Job from other project" do
      before do
        visit trace_project_job_path(project, job2, format: :json)
      end

      it { expect(page.status_code).to eq(404) }
    end
  end
end
