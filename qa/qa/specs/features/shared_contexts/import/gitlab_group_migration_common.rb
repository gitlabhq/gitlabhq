# frozen_string_literal: true

module QA
  RSpec.shared_context(
    'with gitlab group migration',
    :import,
    :orchestrated,
    requires_admin: 'creates a user via API'
  ) do
    let!(:import_wait_duration) { { max_duration: 300, sleep_interval: 2 } }

    # source instance objects
    #
    let!(:source_gitlab_address) { ENV["QA_IMPORT_SOURCE_URL"] || raise("QA_IMPORT_SOURCE_URL is required!") }
    let!(:source_admin_api_client) do
      Runtime::API::Client.new(
        source_gitlab_address,
        personal_access_token: Runtime::Env.admin_personal_access_token || raise("Admin access token missing!"),
        is_new_session: false
      )
    end
    let!(:source_admin_user) { Resource::User.fabricate_via_api! { |usr| usr.api_client = source_admin_api_client } }
    let!(:source_group) do
      Resource::Sandbox.fabricate_via_api! do |group|
        group.api_client = source_admin_api_client
        group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
        group.avatar = File.new("qa/fixtures/designs/tanuki.jpg", "r")
      end
    end

    # target instance objects
    #
    let!(:admin_api_client) { Runtime::API::Client.as_admin }
    let!(:user) { Resource::User.fabricate_via_api! { |usr| usr.api_client = admin_api_client } }
    let!(:api_client) { Runtime::API::Client.new(user: user) }
    let!(:target_sandbox) do
      Resource::Sandbox.fabricate_via_api! do |group|
        group.api_client = admin_api_client
      end
    end

    let(:imported_group) do
      Resource::BulkImportGroup.fabricate_via_api! do |group|
        group.api_client = api_client
        group.sandbox = target_sandbox
        group.source_group = source_group
        group.source_gitlab_address = source_gitlab_address
        group.import_access_token = source_admin_api_client.personal_access_token
      end
    end

    let(:import_failures) do
      imported_group.import_details.sum([]) { |details| details[:failures] }
    end

    before do
      target_sandbox.add_member(user, Resource::Members::AccessLevel::OWNER)
      source_admin_user.set_public_email
    end

    after do |example|
      # Checking for failures in the test currently makes test very flaky due to catching unrelated failures
      # Log failures for easier debugging
      Runtime::Logger.warn("Import failures: #{import_failures}") if example.exception && !import_failures.empty?
    rescue QA::Resource::Base::NoValueError
      # rescue when import did not happen at all
    end
  end
end
