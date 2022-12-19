# frozen_string_literal: true

module QA
  RSpec.shared_context "with github import", :github, :import, :requires_admin, :orchestrated do
    include QA::Support::Data::Github

    let!(:github_repo) { "#{github_username}/import-test" }
    let!(:api_client) { Runtime::API::Client.as_admin }

    let!(:group) do
      Resource::Group.fabricate_via_api! do |resource|
        resource.api_client = api_client
        resource.path = "destination-group-for-import-#{SecureRandom.hex(4)}"
      end
    end

    let!(:user) do
      Resource::User.fabricate_via_api! do |resource|
        resource.api_client = api_client
        resource.hard_delete_on_api_removal = true
      end
    end

    let!(:user_api_client) { Runtime::API::Client.new(user: user) }

    let(:imported_project) do
      Resource::ProjectImportedFromGithub.fabricate_via_api! do |project|
        project.name = 'imported-project'
        project.group = group
        project.github_personal_access_token = Runtime::Env.github_access_token
        project.github_repository_path = github_repo
        project.api_client = user_api_client
        project.issue_events_import = true
        project.full_notes_import = true
      end
    end

    before do
      group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
    end
  end
end
