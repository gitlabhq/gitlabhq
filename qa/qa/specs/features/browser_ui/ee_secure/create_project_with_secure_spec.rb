# frozen_string_literal: true

require 'pathname'

module QA
  context 'Secure', :docker do
    def login
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.perform(&:sign_in_using_credentials)
    end

    describe 'Security Dashboard support' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }

      after do
        Service::Runner.new(executor).remove!
      end

      it 'displays the Dependency Scanning report in the pipeline' do
        login

        @project = Resource::Project.fabricate! do |p|
          p.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          p.description = 'Project with Secure'
        end

        Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = executor
          runner.tags = %w[qa test]
        end

        # Create Secure compatible repo
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
            .new(__dir__)
            .join('../../../../ee/fixtures/secure_premade_reports')
          push.commit_message = 'Create Secure compatible application to serve premade reports'
        end

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('dependency-scanning')
        end
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 600)

          job.click_element(:pipeline_path)
        end
        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_on_security
          expect(pipeline).to have_dependency_report
          expect(pipeline).to have_content("Dependency scanning detected 1")
          pipeline.expand_dependency_report
          expect(pipeline).to have_content("jQuery before 3.4.0")
        end
      end
    end
  end
end
