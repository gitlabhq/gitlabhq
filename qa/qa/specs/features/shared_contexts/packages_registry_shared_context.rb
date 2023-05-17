# frozen_string_literal: true

module QA
  RSpec.shared_context 'packages registry qa scenario' do
    let(:personal_access_token) { Runtime::Env.personal_access_token }

    let(:package_project) do
      Resource::Project.fabricate_via_api! do |project|
        project.name = "#{package_type}_package_project"
        project.initialize_with_readme = true
        project.visibility = :private
      end
    end

    let(:client_project) do
      Resource::Project.fabricate_via_api! do |client_project|
        client_project.name = "#{package_type}_client_project"
        client_project.initialize_with_readme = true
        client_project.group = package_project.group
      end
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
      Resource::Package.init do |package|
        package.name = package_name
        package.project = package_project
      end
    end

    let(:runner) do
      Resource::GroupRunner.fabricate! do |runner|
        runner.name = "qa-runner-#{Time.now.to_i}"
        runner.tags = ["runner-for-#{package_project.group.name}"]
        runner.executor = :docker
        runner.group = package_project.group
      end
    end

    let(:gitlab_address_with_port) do
      uri = URI.parse(Runtime::Scenario.gitlab_address)
      "#{uri.scheme}://#{uri.host}:#{uri.port}"
    end

    let(:project_deploy_token) do
      Resource::ProjectDeployToken.fabricate_via_api! do |deploy_token|
        deploy_token.name = 'package-deploy-token'
        deploy_token.project = package_project
        deploy_token.scopes = %w[
          read_repository
          read_package_registry
          write_package_registry
        ]
      end
    end

    before do
      Flow::Login.sign_in_unless_signed_in
      runner
    end

    after do
      runner.remove_via_api!
      package.remove_via_api!
      package_project.remove_via_api!
      client_project.remove_via_api!
    end
  end
end
