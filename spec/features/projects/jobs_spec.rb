require 'spec_helper'
require 'tempfile'

feature 'Jobs' do
  let(:user) { create(:user) }
  let(:user_access_level) { :developer }
  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }
  let(:job2) { create(:ci_build) }

  let(:artifacts_file) do
    fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif')
  end

  before do
    project.add_role(user, user_access_level)
    sign_in(user)
  end

  describe "GET /:project/jobs" do
    let!(:job) { create(:ci_build,  pipeline: pipeline) }

    context "Pending scope" do
      before do
        visit project_jobs_path(project, scope: :pending)
      end

      it "shows Pending tab jobs" do
        expect(page).to have_link 'Cancel running'
        expect(page).to have_selector('.nav-links li.active', text: 'Pending')
        expect(page).to have_content job.short_sha
        expect(page).to have_content job.ref
        expect(page).to have_content job.name
      end
    end

    context "Running scope" do
      before do
        job.run!
        visit project_jobs_path(project, scope: :running)
      end

      it "shows Running tab jobs" do
        expect(page).to have_selector('.nav-links li.active', text: 'Running')
        expect(page).to have_link 'Cancel running'
        expect(page).to have_content job.short_sha
        expect(page).to have_content job.ref
        expect(page).to have_content job.name
      end
    end

    context "Finished scope" do
      before do
        job.run!
        visit project_jobs_path(project, scope: :finished)
      end

      it "shows Finished tab jobs" do
        expect(page).to have_selector('.nav-links li.active', text: 'Finished')
        expect(page).to have_content 'No jobs to show'
        expect(page).to have_link 'Cancel running'
      end
    end

    context "All jobs" do
      before do
        project.builds.running_or_pending.each(&:success)
        visit project_jobs_path(project)
      end

      it "shows All tab jobs" do
        expect(page).to have_selector('.nav-links li.active', text: 'All')
        expect(page).to have_content job.short_sha
        expect(page).to have_content job.ref
        expect(page).to have_content job.name
        expect(page).not_to have_link 'Cancel running'
      end
    end

    context "when visiting old URL" do
      let(:jobs_url) do
        project_jobs_path(project)
      end

      before do
        visit jobs_url.sub('/-/jobs', '/builds')
      end

      it "redirects to new URL" do
        expect(page.current_path).to eq(jobs_url)
      end
    end
  end

  describe "POST /:project/jobs/:id/cancel_all" do
    before do
      job.run!
      visit project_jobs_path(project)
      click_link "Cancel running"
    end

    it 'shows all necessary content' do
      expect(page).to have_selector('.nav-links li.active', text: 'All')
      expect(page).to have_content 'canceled'
      expect(page).to have_content job.short_sha
      expect(page).to have_content job.ref
      expect(page).to have_content job.name
      expect(page).not_to have_link 'Cancel running'
    end
  end

  describe "GET /:project/jobs/:id" do
    context "Job from project" do
      let(:job) { create(:ci_build, :success, :trace_live, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
      end

      it 'shows status name', :js do
        expect(page).to have_css('.ci-status.ci-success', text: 'passed')
      end

      it 'shows commit`s data' do
        expect(page.status_code).to eq(200)
        expect(page).to have_content pipeline.sha[0..7]
        expect(page).to have_content pipeline.git_commit_message
        expect(page).to have_content pipeline.git_author_name
      end

      it 'shows active job' do
        expect(page).to have_selector('.build-job.active')
      end
    end

    context 'when job is not running', :js do
      let(:job) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
      end

      it 'shows retry button' do
        expect(page).to have_link('Retry')
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
          job_url = project_job_path(project, job)
          options = { issue: { title: button_title, description: "Job [##{job.id}](#{job_url}) failed for #{job.sha}:\n" } }

          href = new_project_issue_path(project, options)

          page.within('.header-action-buttons') do
            expect(find('.js-new-issue')['href']).to include(href)
          end
        end
      end
    end

    context "Job from other project" do
      before do
        visit project_job_path(project, job2)
      end

      it { expect(page.status_code).to eq(404) }
    end

    context "Download artifacts" do
      before do
        job.update_attributes(legacy_artifacts_file: artifacts_file)
        visit project_job_path(project, job)
      end

      it 'has button to download artifacts' do
        expect(page).to have_content 'Download'
      end
    end

    context 'Artifacts expire date' do
      before do
        job.update_attributes(legacy_artifacts_file: artifacts_file,
                              artifacts_expire_at: expire_at)

        visit project_job_path(project, job)
      end

      context 'no expire date defined' do
        let(:expire_at) { nil }

        it 'does not have the Keep button' do
          expect(page).not_to have_content 'Keep'
        end
      end

      context 'when expire date is defined' do
        let(:expire_at) { Time.now + 7.days }

        context 'when user has ability to update job' do
          it 'keeps artifacts when keep button is clicked' do
            expect(page).to have_content 'The artifacts will be removed'

            click_link 'Keep'

            expect(page).to have_no_link 'Keep'
            expect(page).to have_no_content 'The artifacts will be removed'
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
        let(:expire_at) { Time.now - 7.days }

        it 'does not have the Keep button' do
          expect(page).to have_content 'The artifacts were removed'
          expect(page).not_to have_link 'Keep'
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
        expect(page.current_path).to eq(job_url)
      end
    end

    feature 'Raw trace' do
      before do
        job.run!

        visit project_job_path(project, job)
      end

      it do
        expect(page).to have_css('.js-raw-link')
      end
    end

    feature 'HTML trace', :js do
      before do
        job.run!

        visit project_job_path(project, job)
      end

      context 'when job has an initial trace' do
        it 'loads job trace' do
          expect(page).to have_content 'BUILD TRACE'

          job.trace.write do |stream|
            stream.append(' and more trace', 11)
          end

          expect(page).to have_content 'BUILD TRACE and more trace'
        end
      end
    end

    feature 'Variables' do
      let(:trigger_request) { create(:ci_trigger_request) }

      let(:job) do
        create :ci_build, pipeline: pipeline, trigger_request: trigger_request
      end

      shared_examples 'expected variables behavior' do
        it 'shows variable key and value after click', :js do
          expect(page).to have_css('.js-reveal-variables')
          expect(page).not_to have_css('.js-build-variable')
          expect(page).not_to have_css('.js-build-value')

          click_button 'Reveal Variables'

          expect(page).not_to have_css('.js-reveal-variables')
          expect(page).to have_selector('.js-build-variable', text: 'TRIGGER_KEY_1')
          expect(page).to have_selector('.js-build-value', text: 'TRIGGER_VALUE_1')
        end
      end

      context 'when variables are stored in trigger_request' do
        before do
          trigger_request.update_attribute(:variables, { 'TRIGGER_KEY_1' => 'TRIGGER_VALUE_1' } )

          visit project_job_path(project, job)
        end

        it_behaves_like 'expected variables behavior'
      end

      context 'when variables are stored in pipeline_variables' do
        before do
          create(:ci_pipeline_variable, pipeline: pipeline, key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1')

          visit project_job_path(project, job)
        end

        it_behaves_like 'expected variables behavior'
      end
    end

    context 'when job starts environment' do
      let(:environment) { create(:environment, project: project) }
      let(:pipeline) { create(:ci_pipeline, project: project) }

      context 'job is successfull and has deployment' do
        let(:deployment) { create(:deployment) }
        let(:job) { create(:ci_build, :success, :trace_artifact, environment: environment.name, deployments: [deployment], pipeline: pipeline) }

        it 'shows a link for the job' do
          visit project_job_path(project, job)

          expect(page).to have_link environment.name
        end
      end

      context 'job is complete and not successful' do
        let(:job) { create(:ci_build, :failed, :trace_artifact, environment: environment.name, pipeline: pipeline) }

        it 'shows a link for the job' do
          visit project_job_path(project, job)

          expect(page).to have_link environment.name
        end
      end

      context 'job creates a new deployment' do
        let!(:deployment) { create(:deployment, environment: environment, sha: project.commit.id) }
        let(:job) { create(:ci_build, :success, :trace_artifact, environment: environment.name, pipeline: pipeline) }

        it 'shows a link to latest deployment' do
          visit project_job_path(project, job)

          expect(page).to have_link('latest deployment')
        end
      end
    end

    context 'Playable manual action' do
      let(:job) { create(:ci_build, :playable, pipeline: pipeline) }

      before do
        project.add_developer(user)
        visit project_job_path(project, job)
      end

      it 'shows manual action empty state' do
        expect(page).to have_content(job.detailed_status(user).illustration[:title])
        expect(page).to have_content('This job requires a manual action')
        expect(page).to have_content('This job depends on a user to trigger its process. Often they are used to deploy code to production environments')
        expect(page).to have_link('Trigger this manual action')
      end

      it 'plays manual action and shows pending status', :js do
        click_link 'Trigger this manual action'

        wait_for_requests
        expect(page).to have_content('This job has not started yet')
        expect(page).to have_content('This job is in pending state and is waiting to be picked by a runner')
        expect(page).to have_content('pending')
      end
    end

    context 'Non triggered job' do
      let(:job) { create(:ci_build, :created, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
      end

      it 'shows empty state' do
        expect(page).to have_content(job.detailed_status(user).illustration[:title])
        expect(page).to have_content('This job has not been triggered yet')
        expect(page).to have_content('This job depends on upstream jobs that need to succeed in order for this job to be triggered')
      end
    end

    context 'Pending job' do
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

    context 'Canceled job' do
      context 'with log' do
        let(:job) { create(:ci_build, :canceled, :trace_artifact, pipeline: pipeline) }

        before do
          visit project_job_path(project, job)
        end

        it 'renders job log' do
          expect(page).to have_selector('.js-build-output')
        end
      end

      context 'without log' do
        let(:job) { create(:ci_build, :canceled, pipeline: pipeline) }

        before do
          visit project_job_path(project, job)
        end

        it 'renders empty state' do
          expect(page).to have_content(job.detailed_status(user).illustration[:title])
          expect(page).not_to have_selector('.js-build-output')
          expect(page).to have_content('This job has been canceled')
        end
      end
    end

    context 'Skipped job' do
      let(:job) { create(:ci_build, :skipped, pipeline: pipeline) }

      before do
        visit project_job_path(project, job)
      end

      it 'renders empty state' do
        expect(page).to have_content(job.detailed_status(user).illustration[:title])
        expect(page).not_to have_selector('.js-build-output')
        expect(page).to have_content('This job has been skipped')
      end
    end

    context 'when job is failed but has no trace' do
      let(:job) { create(:ci_build, :failed, pipeline: pipeline) }

      it 'renders empty state' do
        visit project_job_path(project, job)

        expect(job).not_to have_trace
        expect(page).to have_content('This job does not have a trace.')
      end
    end
  end

  describe "POST /:project/jobs/:id/cancel", :js do
    context "Job from project" do
      before do
        job.run!
        visit project_job_path(project, job)
        find('.js-cancel-job').click()
      end

      it 'loads the page and shows all needed controls' do
        expect(page).to have_content 'Retry'
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

        find('.js-retry-button').click
      end

      it 'shows the right status and buttons' do
        page.within('aside.right-sidebar') do
          expect(page).to have_content 'Cancel'
        end
      end
    end

    context "Job that current user is not allowed to retry" do
      before do
        job.run!
        job.cancel!
        project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

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
  end

  describe "GET /:project/jobs/:id/download" do
    before do
      job.update_attributes(legacy_artifacts_file: artifacts_file)
      visit project_job_path(project, job)
      click_link 'Download'
    end

    context "Build from other project" do
      before do
        job2.update_attributes(legacy_artifacts_file: artifacts_file)
        visit download_project_job_artifacts_path(project, job2)
      end

      it { expect(page.status_code).to eq(404) }
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

    context 'storage form' do
      let(:existing_file) { Tempfile.new('existing-trace-file').path }

      before do
        job.run!
      end

      context 'when job has trace in file', :js do
        before do
          allow_any_instance_of(Gitlab::Ci::Trace)
            .to receive(:paths)
            .and_return([existing_file])
        end

        it 'sends the right headers' do
          requests = inspect_requests(inject_headers: { 'X-Sendfile-Type' => 'X-Sendfile' }) do
            visit raw_project_job_path(project, job)
          end
          expect(requests.first.response_headers['Content-Type']).to eq('text/plain; charset=utf-8')
          expect(requests.first.response_headers['X-Sendfile']).to eq(existing_file)
        end
      end

      context 'when job has trace in the database', :js do
        before do
          allow_any_instance_of(Gitlab::Ci::Trace)
            .to receive(:paths)
            .and_return([])

          visit project_job_path(project, job)
        end

        it 'sends the right headers' do
          expect(page).not_to have_selector('.js-raw-link-controller')
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
        expect(page.current_path).to eq(raw_job_url)
      end
    end
  end

  describe "GET /:project/jobs/:id/trace.json" do
    context "Job from project" do
      before do
        visit trace_project_job_path(project, job, format: :json)
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

  describe "GET /:project/jobs/:id/status" do
    context "Job from project" do
      before do
        visit status_project_job_path(project, job)
      end

      it { expect(page.status_code).to eq(200) }
    end

    context "Job from other project" do
      before do
        visit status_project_job_path(project, job2)
      end

      it { expect(page.status_code).to eq(404) }
    end
  end
end
