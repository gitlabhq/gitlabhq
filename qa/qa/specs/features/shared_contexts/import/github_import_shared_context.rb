# frozen_string_literal: true

module QA
  RSpec.shared_context "with github import", :github, :import, :requires_admin, :orchestrated do
    include QA::Support::Data::Github

    let(:import_wait_duration) { 240 }

    let!(:github_repo) { "#{github_username}/import-test" }
    let!(:api_client) { Runtime::API::Client.as_admin }

    let!(:group) do
      create(:group, api_client: api_client, path: "destination-group-for-import-#{SecureRandom.hex(4)}")
    end

    let!(:user) { Runtime::User::Store.test_user }
    let!(:user_api_client) { user.api_client }

    let(:imported_project) do
      Resource::ProjectImportedFromGithub.fabricate_via_api! do |project|
        project.name = 'imported-project'
        project.github_repo_id = '466994992'
        project.group = group
        project.github_personal_access_token = Runtime::Env.github_access_token
        project.github_repository_path = github_repo
        project.api_client = user_api_client
        project.full_notes_import = true
      end
    end

    let(:smocker_host) { ENV["QA_SMOCKER_HOST"] }
    let(:smocker) do
      Vendor::Smocker::SmockerApi.new(
        host: smocker_host,
        public_port: 443,
        admin_port: 8081,
        tls: true
      )
    end

    let(:mocks_path) { Runtime::Path.fixture("mocks", "import") }

    before do
      set_mocks
      group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
    end

    after do
      verify_mocks
    end

    def expect_project_import_finished_successfully
      imported_project.reload! # import the project

      status = nil
      Support::Retrier.retry_until(max_duration: import_wait_duration, sleep_interval: 1, raise_on_failure: false) do
        status = imported_project.project_import_status[:import_status]
        %w[finished failed].include?(status)
      end

      # finished status means success, all other statuses are considered to fail the test
      expect(status).to eq('finished'), "Expected import to finish successfully, but status was: #{status}"
    end

    # Setup github mocked responses if mock server host is present
    #
    # @return [void]
    def set_mocks
      return Runtime::Logger.warn("Mock host is not set, skipping github response setup") unless smocker_host

      mock_definition = ENV["QA_PROXY_GITHUB_REQUESTS"] == "true" ? "github_proxy.yml" : "github_import.yml"

      smocker.reset
      smocker.register(File.read(File.join(mocks_path, mock_definition)))
    end

    # Verify mock session
    #
    # @return [void]
    def verify_mocks
      return Runtime::Logger.warn("Mock host is not set, skipping verify step") unless smocker_host

      verify_response = smocker.verify
      return if verify_response.success?

      raise "Mock failures detected:\n#{JSON.pretty_generate(verify_response.failures)}"
    end
  end
end
