# frozen_string_literal: true

module QA
  RSpec.shared_context(
    'with gitlab group migration',
    :import,
    :orchestrated,
    requires_admin: 'creates a user via API'
  ) do
    let!(:import_wait_duration) { { max_duration: 120, sleep_interval: 2 } }

    # source instance objects
    let!(:source_gitlab_address) { ENV["QA_IMPORT_SOURCE_URL"] || raise("QA_IMPORT_SOURCE_URL is required!") }
    let!(:source_admin_api_client) do
      Runtime::API::Client.new(
        source_gitlab_address,
        personal_access_token: Runtime::Env.admin_personal_access_token || raise("Admin access token missing!"),
        is_new_session: false
      )
    end

    let!(:source_bulk_import_enabled) do
      Runtime::ApplicationSettings.get_application_settings(api_client: source_admin_api_client)[:bulk_import_enabled]
    end

    let!(:source_admin_user) do
      create(:user,
        :set_public_email,
        api_client: source_admin_api_client,
        username: Runtime::Env.admin_username || 'root')
    end

    let!(:source_group) do
      create(:sandbox,
        api_client: source_admin_api_client,
        path: "source-group-for-import-#{SecureRandom.hex(4)}",
        avatar: File.new(Runtime::Path.fixture('designs', 'tanuki.jpg'), "r"))
    end

    # target instance objects
    let!(:admin_api_client) { Runtime::API::Client.as_admin }

    let!(:target_bulk_import_enabled) do
      Runtime::ApplicationSettings.get_application_settings(api_client: admin_api_client)[:bulk_import_enabled]
    end

    let!(:admin_user) do
      create(:user,
        :set_public_email,
        api_client: admin_api_client,
        username: Runtime::Env.admin_username || 'root')
    end

    let!(:user) { create(:user, api_client: admin_api_client, username: "target-user-#{SecureRandom.hex(6)}") }
    let!(:api_client) { Runtime::API::Client.new(user: user) }
    let!(:target_sandbox) { create(:sandbox, api_client: admin_api_client) }

    let(:destination_group_path) { source_group.path }
    let(:imported_group) do
      Resource::BulkImportGroup.fabricate_via_api! do |group|
        group.api_client = api_client
        group.sandbox = target_sandbox
        group.source_group = source_group
        group.source_gitlab_address = source_gitlab_address
        group.destination_group_path = destination_group_path
        group.import_access_token = source_admin_api_client.personal_access_token
      end
    end

    let(:import_failures) do
      imported_group.import_details.sum([]) { |details| details[:failures] }
    end

    def expect_group_import_finished_successfully
      imported_group # trigger import

      import_status = -> {
        status = Support::Retrier.retry_on_exception(
          sleep_interval: 1,
          log: false,
          message: "Fetching import status"
        ) do
          imported_group.import_status
        end
        # fail fast if import explicitly failed, we don't test negative scenarios where we expect failed status
        raise "Import of '#{imported_group.full_path}' failed!" if status == 'failed'

        status
      }

      expect(import_status).to eventually_eq('finished').within(**import_wait_duration)
    end

    before do
      enable_bulk_import(source_admin_api_client) if source_admin_user && !source_bulk_import_enabled
      enable_bulk_import(admin_api_client) unless target_bulk_import_enabled

      target_sandbox.add_member(user, Resource::Members::AccessLevel::OWNER)
    end

    after do |example|
      # Checking for failures in the test currently makes test very flaky due to catching unrelated failures
      # Log failures for easier debugging
      Runtime::Logger.error("Import failures: #{import_failures}") if example.exception && !import_failures.empty?
    rescue StandardError
      # rescue when import did not happen at all and checking import failures will raise an error
    end

    def enable_bulk_import(api_client)
      Runtime::ApplicationSettings.set_application_settings(api_client: api_client, bulk_import_enabled: true)
    end
  end
end
