# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Default branch name instance setting', :requires_admin, :skip_live_env, product_group: :source_code do
      before(:context) do
        Runtime::ApplicationSettings.set_application_settings(default_branch_name: 'main')
      end

      after(:context) do
        Runtime::ApplicationSettings.restore_application_settings(:default_branch_name)
      end

      it 'sets the default branch name for a new project',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347837' do
        project = create(:project, :with_readme, name: 'default-branch-name')

        # It takes a moment to create the project. We wait until we
        # know it exists before we try to clone it
        Support::Waiter.wait_until { project.has_file?('README.md') }

        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.clone

          expect(repository.current_branch).to eq('main')
        end
      end

      it 'allows a project to be created via the CLI with a different default branch name',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347838' do
        project_name = "default-branch-name-via-cli-#{SecureRandom.hex(8)}"
        group = create(:group)

        Git::Repository.perform do |repository|
          repository.init_repository
          repository.uri = "#{Runtime::Scenario.gitlab_address}/#{group.full_path}/#{project_name}"
          repository.use_default_credentials
          repository.use_default_identity
          repository.checkout('trunk', new_branch: true)
          repository.commit_file('README.md', 'Created via the CLI', 'initial commit via CLI')
          repository.push_changes('trunk')
        end

        project = create(:project, add_name_uuid: false, name: project_name, group: group)

        expect(project.default_branch).to eq('trunk')
        expect(project).to have_file('README.md')
        expect(project.commits.map { |commit| commit[:message].chomp })
          .to include('initial commit via CLI')
      end
    end
  end
end
