# frozen_string_literal: true
require 'securerandom'

module QA
  RSpec.describe 'Create', :requires_admin, :skip_live_env, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/195179', type: :flaky } do
    describe 'Jenkins integration' do
      let(:project_name) { "project_with_jenkins_#{SecureRandom.hex(4)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = project_name
          project.initialize_with_readme = true
          project.auto_devops_enabled = false
        end
      end

      before do
        jenkins_server = run_jenkins_server

        Vendor::Jenkins::Page::Base.host = jenkins_server.host_address

        Runtime::Env.personal_access_token ||= fabricate_personal_access_token

        allow_requests_to_local_networks

        setup_jenkins
      end

      it 'integrates and displays build status for MR pipeline in GitLab', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/719' do
        login_to_gitlab

        setup_project_integration_with_jenkins

        expect(page).to have_text("Jenkins CI activated.")

        QA::Support::Retrier.retry_on_exception do
          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.new_branch = false
            push.file_name = "file_#{SecureRandom.hex(4)}.txt"
          end

          Vendor::Jenkins::Page::LastJobConsole.perform do |job_console|
            job_console.job_name = project_name

            job_console.visit!

            Support::Waiter.wait_until(sleep_interval: 2, reload_page: page) do
              job_console.has_successful_build? && job_console.no_failed_status_update?
            end
          end

          project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |show|
            expect(show).to have_build('jenkins', status: :success, wait: 15)
          end
        end
      end

      after do
        remove_jenkins_server
      end

      def setup_jenkins
        Vendor::Jenkins::Page::Login.perform do |login_page|
          login_page.visit!
          login_page.login
        end

        token_description = "token-#{SecureRandom.hex(8)}"

        Vendor::Jenkins::Page::NewCredentials.perform do |new_credentials|
          new_credentials.visit_and_set_gitlab_api_token(Runtime::Env.personal_access_token, token_description)
        end

        Vendor::Jenkins::Page::Configure.perform do |configure|
          configure.visit_and_setup_gitlab_connection(patch_host_name(Runtime::Scenario.gitlab_address, 'gitlab'), token_description) do
            configure.click_test_connection
            expect(configure).to have_success
          end
        end

        Vendor::Jenkins::Page::NewJob.perform do |new_job|
          new_job.visit_and_create_new_job_with_name(project_name)
        end

        Vendor::Jenkins::Page::ConfigureJob.perform do |configure_job|
          configure_job.job_name = project_name
          configure_job.configure(scm_url: patch_host_name(project.repository_http_location.git_uri, 'gitlab'))
        end
      end

      def run_jenkins_server
        Service::DockerRun::Jenkins.new.tap do |runner|
          runner.pull
          runner.register!
        end
      end

      def remove_jenkins_server
        Service::DockerRun::Jenkins.new.remove!
      end

      def fabricate_personal_access_token
        login_to_gitlab

        token = Resource::PersonalAccessToken.fabricate!.token
        Page::Main::Menu.perform(&:sign_out)
        token
      end

      def login_to_gitlab
        Flow::Login.sign_in
      end

      def patch_host_name(host_name, container_name)
        return host_name unless host_name.include?('localhost')

        ip_address = `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' #{container_name}`.strip
        host_name.gsub('localhost', ip_address)
      end

      def setup_project_integration_with_jenkins
        project.visit!

        Page::Project::Menu.perform(&:click_project)
        Page::Project::Menu.perform(&:go_to_integrations_settings)
        Page::Project::Settings::Integrations.perform(&:click_jenkins_ci_link)

        QA::Page::Project::Settings::Services::Jenkins.perform do |jenkins|
          jenkins.setup_service_with(jenkins_url: patch_host_name(Vendor::Jenkins::Page::Base.host, 'jenkins-server'),
            project_name: project_name)
        end
      end

      def allow_requests_to_local_networks
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
        Flow::Login.sign_in_as_admin
        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_network_settings)

        Page::Admin::Settings::Network.perform do |network|
          network.expand_outbound_requests do |outbound_requests|
            outbound_requests.allow_requests_to_local_network_from_services
          end
        end

        Page::Main::Menu.perform(&:sign_out)
      end
    end
  end
end
