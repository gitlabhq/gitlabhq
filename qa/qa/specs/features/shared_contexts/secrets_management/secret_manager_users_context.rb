# frozen_string_literal: true

module QA
  RSpec.shared_context 'secrets manager with all users' do
    include_context 'secrets manager base'

    def maintainer
      @maintainer ||= create(:user)
    end

    def reporter
      @reporter ||= create(:user)
    end

    def non_project_user
      @non_project_user ||= create(:user)
    end

    def non_project_owner
      @non_project_owner ||= create(:user)
    end

    def other_project
      @other_project ||= create(:project, :with_readme, name: 'other-project-for-testing',
        api_client: Runtime::User::Store.admin_api_client)
    end

    def sandbox_group
      @sandbox_group ||= create(:sandbox, api_client: Runtime::User::Store.admin_api_client)
    end

    def group
      @group ||= create(:group, sandbox: sandbox_group, api_client: Runtime::User::Store.admin_api_client)
    end

    before(:context) do
      project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
      project.add_member(reporter, Resource::Members::AccessLevel::REPORTER)
      other_project.add_member(non_project_owner, Resource::Members::AccessLevel::OWNER)
      project.invite_group(group, Resource::Members::AccessLevel::DEVELOPER)
    end
  end
end
