require 'spec_helper'
require 'tempfile'

feature 'Jobs', :feature do
  let(:user) { create(:user) }
  let(:user_access_level) { :developer }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :trace, pipeline: pipeline) }
  let(:build2) { create(:ci_build) }

  let(:artifacts_file) do
    fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif')
  end

  before do
    project.team << [user, user_access_level]
    login_as(user)
  end

  describe "GET /:project/jobs" do
    let!(:build) { create(:ci_build,  pipeline: pipeline) }

    context "Pending scope" do
      before do
        visit namespace_project_jobs_path(project.namespace, project, scope: :pending)
      end

      it "shows Pending tab jobs" do
        expect(page).to have_link 'Cancel running'
        expect(page).to have_selector('.nav-links li.active', text: 'Pending')
        expect(page).to have_content build.short_sha
        expect(page).to have_content build.ref
        expect(page).to have_content build.name
      end
    end

    context "Running scope" do
      before do
        build.run!
        visit namespace_project_jobs_path(project.namespace, project, scope: :running)
      end

      it "shows Running tab jobs" do
        expect(page).to have_selector('.nav-links li.active', text: 'Running')
        expect(page).to have_link 'Cancel running'
        expect(page).to have_content build.short_sha
        expect(page).to have_content build.ref
        expect(page).to have_content build.name
      end
    end

    context "Finished scope" do
      before do
        build.run!
        visit namespace_project_jobs_path(project.namespace, project, scope: :finished)
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
        visit namespace_project_jobs_path(project.namespace, project)
      end

      it "shows All tab jobs" do
        expect(page).to have_selector('.nav-links li.active', text: 'All')
        expect(page).to have_content build.short_sha
        expect(page).to have_content build.ref
        expect(page).to have_content build.name
        expect(page).not_to have_link 'Cancel running'
      end
    end

    context "when visiting old URL" do
      let(:jobs_url) do
        namespace_project_jobs_path(project.namespace, project)
      end

      before do
        visit jobs_url.sub('jobs', 'builds')
      end

      it "redirects to new URL" do
        expect(page.current_path).to eq(jobs_url)
      end
    end
  end

  describe "POST /:project/jobs/:id/cancel_all" do
    before do
      build.run!
      visit namespace_project_jobs_path(project.namespace, project)
      click_link "Cancel running"
    end

    it 'shows all necessary content' do
      expect(page).to have_selector('.nav-links li.active', text: 'All')
      expect(page).to have_content 'canceled'
      expect(page).to have_content build.short_sha
      expect(page).to have_content build.ref
      expect(page).to have_content build.name
      expect(page).not_to have_link 'Cancel running'
    end
  end

  describe "GET /:project/jobs/:id" do
    context "Job from project" do
      before do
        visit namespace_project_job_path(project.namespace, project, build)
      end

      it 'shows commit`s data' do
        expect(page.status_code).to eq(200)
        expect(page).to have_content pipeline.sha[0..7]
        expect(page).to have_content pipeline.git_commit_message
        expect(page).to have_content pipeline.git_author_name
      end

      it 'shows active build' do
        expect(page).to have_selector('.build-job.active')
      end
    end

    context "Job from other project" do
      before do
        visit namespace_project_job_path(project.namespace, project, build2)
      end

      it { expect(page.status_code).to eq(404) }
    end

    context "Download artifacts" do
      before do
        build.update_attributes(artifacts_file: artifacts_file)
        visit namespace_project_job_path(project.namespace, project, build)
      end

      it 'has button to download artifacts' do
        expect(page).to have_content 'Download'
      end
    end

    context 'Artifacts expire date' do
      before do
        build.update_attributes(artifacts_file: artifacts_file,
                                artifacts_expire_at: expire_at)

        visit namespace_project_job_path(project.namespace, project, build)
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
        namespace_project_job_path(project.namespace, project, build)
      end

      before do
        visit job_url.sub('jobs', 'builds')
      end

      it "redirects to new URL" do
        expect(page.current_path).to eq(job_url)
      end
    end

    feature 'Raw trace' do
      before do
        build.run!

        visit namespace_project_job_path(project.namespace, project, build)
      end

      it do
        expect(page).to have_link 'Raw'
      end
    end

    feature 'HTML trace', :js do
      before do
        build.run!

        visit namespace_project_job_path(project.namespace, project, build)
      end

      context 'when job has an initial trace' do
        it 'loads job trace' do
          expect(page).to have_content 'BUILD TRACE'

          build.trace.write do |stream|
            stream.append(' and more trace', 11)
          end

          expect(page).to have_content 'BUILD TRACE and more trace'
        end
      end
    end

    feature 'Variables' do
      let(:trigger_request) { create(:ci_trigger_request_with_variables) }

      let(:build) do
        create :ci_build, pipeline: pipeline, trigger_request: trigger_request
      end

      before do
        visit namespace_project_job_path(project.namespace, project, build)
      end

      it 'shows variable key and value after click', js: true do
        expect(page).to have_css('.reveal-variables')
        expect(page).not_to have_css('.js-build-variable')
        expect(page).not_to have_css('.js-build-value')

        click_button 'Reveal Variables'

        expect(page).not_to have_css('.reveal-variables')
        expect(page).to have_selector('.js-build-variable', text: 'TRIGGER_KEY_1')
        expect(page).to have_selector('.js-build-value', text: 'TRIGGER_VALUE_1')
      end
    end

    context 'when job starts environment' do
      let(:environment) { create(:environment, project: project) }
      let(:pipeline) { create(:ci_pipeline, project: project) }

      context 'job is successfull and has deployment' do
        let(:deployment) { create(:deployment) }
        let(:build) { create(:ci_build, :success, environment: environment.name, deployments: [deployment], pipeline: pipeline) }

        it 'shows a link for the job' do
          visit namespace_project_job_path(project.namespace, project, build)

          expect(page).to have_link environment.name
        end
      end

      context 'job is complete and not successfull' do
        let(:build) { create(:ci_build, :failed, environment: environment.name, pipeline: pipeline) }

        it 'shows a link for the job' do
          visit namespace_project_job_path(project.namespace, project, build)

          expect(page).to have_link environment.name
        end
      end

      context 'job creates a new deployment' do
        let!(:deployment) { create(:deployment, environment: environment, sha: project.commit.id) }
        let(:build) { create(:ci_build, :success, environment: environment.name, pipeline: pipeline) }

        it 'shows a link to latest deployment' do
          visit namespace_project_job_path(project.namespace, project, build)

          expect(page).to have_link('latest deployment')
        end
      end
    end
  end

  describe "POST /:project/builds/:id/cancel" do
    context "Job from project" do
      before do
        build.run!
        visit namespace_project_job_path(project.namespace, project, build)
        click_link "Cancel"
      end

      it 'loads the page and shows all needed controls' do
        expect(page.status_code).to eq(200)
        expect(page).to have_content 'canceled'
        expect(page).to have_content 'Retry'
      end
    end

    context "Job from other project" do
      before do
        build.run!
        visit namespace_project_job_path(project.namespace, project, build)
        page.driver.post(cancel_namespace_project_job_path(project.namespace, project, build2))
      end

      it { expect(page.status_code).to eq(404) }
    end
  end

  describe "POST /:project/builds/:id/retry" do
    context "Job from project" do
      before do
        build.run!
        visit namespace_project_job_path(project.namespace, project, build)
        click_link 'Cancel'
        page.within('.build-header') do
          click_link 'Retry job'
        end
      end

      it 'shows the right status and buttons' do
        expect(page).to have_http_status(200)
        expect(page).to have_content 'pending'
        page.within('aside.right-sidebar') do
          expect(page).to have_content 'Cancel'
        end
      end
    end

    context "Build from other project" do
      before do
        build.run!
        visit namespace_project_job_path(project.namespace, project, build)
        click_link 'Cancel'
        page.driver.post(retry_namespace_project_job_path(project.namespace, project, build2))
      end

      it { expect(page).to have_http_status(404) }
    end

    context "Build that current user is not allowed to retry" do
      before do
        build.run!
        build.cancel!
        project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

        logout_direct
        login_with(create(:user))
        visit namespace_project_job_path(project.namespace, project, build)
      end

      it 'does not show the Retry button' do
        page.within('aside.right-sidebar') do
          expect(page).not_to have_content 'Retry'
        end
      end
    end
  end

  describe "GET /:project/builds/:id/download" do
    before do
      build.update_attributes(artifacts_file: artifacts_file)
      visit namespace_project_job_path(project.namespace, project, build)
      click_link 'Download'
    end

    context "Build from other project" do
      before do
        build2.update_attributes(artifacts_file: artifacts_file)
        visit download_namespace_project_job_artifacts_path(project.namespace, project, build2)
      end

      it { expect(page.status_code).to eq(404) }
    end
  end

  describe 'GET /:project/builds/:id/raw' do
    context 'access source' do
      context 'build from project' do
        before do
          Capybara.current_session.driver.header('X-Sendfile-Type', 'X-Sendfile')
          build.run!
          visit namespace_project_job_path(project.namespace, project, build)
          page.within('.js-build-sidebar') { click_link 'Raw' }
        end

        it 'sends the right headers' do
          expect(page.status_code).to eq(200)
          expect(page.response_headers['Content-Type']).to eq('text/plain; charset=utf-8')
          expect(page.response_headers['X-Sendfile']).to eq(build.trace.send(:current_path))
        end
      end

      context 'build from other project' do
        before do
          Capybara.current_session.driver.header('X-Sendfile-Type', 'X-Sendfile')
          build2.run!
          visit raw_namespace_project_job_path(project.namespace, project, build2)
        end

        it 'sends the right headers' do
          expect(page.status_code).to eq(404)
        end
      end
    end

    context 'storage form' do
      let(:existing_file) { Tempfile.new('existing-trace-file').path }

      before do
        Capybara.current_session.driver.header('X-Sendfile-Type', 'X-Sendfile')

        build.run!

        allow_any_instance_of(Gitlab::Ci::Trace).to receive(:paths)
          .and_return(paths)

        visit namespace_project_job_path(project.namespace, project, build)
      end

      context 'when build has trace in file' do
        let(:paths) do
          [existing_file]
        end

        before do
          page.within('.js-build-sidebar') { click_link 'Raw' }
        end

        it 'sends the right headers' do
          expect(page.status_code).to eq(200)
          expect(page.response_headers['Content-Type']).to eq('text/plain; charset=utf-8')
          expect(page.response_headers['X-Sendfile']).to eq(existing_file)
        end
      end

      context 'when build has trace in DB' do
        let(:paths) { [] }

        it 'sends the right headers' do
          expect(page.status_code).not_to have_link('Raw')
        end
      end
    end

    context "when visiting old URL" do
      let(:raw_job_url) do
        raw_namespace_project_job_path(project.namespace, project, build)
      end

      before do
        visit raw_job_url.sub('jobs', 'builds')
      end

      it "redirects to new URL" do
        expect(page.current_path).to eq(raw_job_url)
      end
    end
  end

  describe "GET /:project/builds/:id/trace.json" do
    context "Build from project" do
      before do
        visit trace_namespace_project_job_path(project.namespace, project, build, format: :json)
      end

      it { expect(page.status_code).to eq(200) }
    end

    context "Build from other project" do
      before do
        visit trace_namespace_project_job_path(project.namespace, project, build2, format: :json)
      end

      it { expect(page.status_code).to eq(404) }
    end

    context "when visiting old URL" do
      let(:trace_job_url) do
        trace_namespace_project_job_path(project.namespace, project, build,format: :json)
      end

      before do
        visit trace_job_url.sub('jobs', 'builds')
      end

      it "redirects to new URL" do
        expect(page.current_path).to eq(trace_job_url)
      end
    end
  end

  describe "GET /:project/builds/:id/status" do
    context "Build from project" do
      before do
        visit status_namespace_project_job_path(project.namespace, project, build)
      end

      it { expect(page.status_code).to eq(200) }
    end

    context "Build from other project" do
      before do
        visit status_namespace_project_job_path(project.namespace, project, build2)
      end

      it { expect(page.status_code).to eq(404) }
    end

    context "when visiting old URL" do
      let(:status_job_url) do
        status_namespace_project_job_path(project.namespace, project, build)
      end

      before do
        visit status_job_url.sub('jobs', 'builds')
      end

      it "redirects to new URL" do
        expect(page.current_path).to eq(status_job_url)
      end
    end
  end
end
