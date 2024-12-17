# frozen_string_literal: true

module QA
  RSpec.shared_context 'packages registry qa scenario' do
    let(:api_client) { Runtime::User::Store.default_api_client }
    let(:personal_access_token) { api_client.personal_access_token }
    let(:package_project) { create(:project, :private, :with_readme, name: "packages", api_client: api_client) }

    let(:client_project) do
      create(:project, :with_readme, name: "client-#{SecureRandom.hex(8)}", group: package_project.group)
    end

    let(:package_project_inbound_job_token_disabled) do
      Resource::CICDSettings.fabricate_via_api! do |settings|
        settings.project_path = package_project.full_path
        settings.inbound_job_token_scope_enabled = false
      end
    end

    let(:client_project_inbound_job_token_disabled) do
      Resource::CICDSettings.fabricate_via_api! do |settings|
        settings.project_path = client_project.full_path
        settings.inbound_job_token_scope_enabled = false
      end
    end

    let(:package) do
      build(:package, name: package_name, project: package_project)
    end

    let!(:runner) do
      create(:group_runner,
        name: "qa-runner-#{SecureRandom.hex(6)}",
        tags: ["runner-for-#{package_project.group.name}"],
        executor: :docker,
        group: package_project.group)
    end

    let(:gitlab_address_with_port) do
      Support::GitlabAddress.address_with_port
    end

    let(:project_deploy_token) do
      create(:project_deploy_token,
        name: 'package-deploy-token',
        project: package_project,
        scopes: %w[
          read_repository
          read_package_registry
          write_package_registry
        ])
    end

    before do
      Flow::Login.sign_in_unless_signed_in
    end

    after do
      runner.remove_via_api!
    end
  end
end
