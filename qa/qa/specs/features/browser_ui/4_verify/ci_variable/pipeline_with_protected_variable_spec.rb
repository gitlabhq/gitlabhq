# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, :requires_admin, product_group: :pipeline_authoring do
    describe 'Pipeline with protected variable' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:protected_value) { Faker::Alphanumeric.alphanumeric(number: 8) }
      let(:project) { create(:project, name: 'project-with-ci-vars', description: 'project with CI vars') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }
      let!(:ci_file) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              job:
                tags:
                  - #{executor}
                script: echo $PROTECTED_VARIABLE
            YAML
          }
        ])
      end

      let!(:developer) { create(:user, :with_personal_access_token) }
      let!(:maintainer) { create(:user, :with_personal_access_token) }

      before do
        project.add_member(developer)
        project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
        add_ci_variable
      end

      after do
        runner.remove_via_api!
      end

      it 'exposes variable on protected branch',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348005' do
        create_protected_branch

        [developer, maintainer].each do |user|
          user_commit_to_protected_branch(user.api_client)
          go_to_pipeline_job_as(user)
          Page::Project::Job::Show.perform do |show|
            expect(show.output).to have_content(protected_value), 'Expect protected variable to be in job log.'
          end
        end
      end

      it 'does not expose variable on unprotected branch', :smoke,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347664' do
        [developer, maintainer].each do |user|
          user_create_merge_request(user.api_client)
          go_to_pipeline_job_as(user)
          Page::Project::Job::Show.perform do |show|
            expect(show.output).to have_no_content(protected_value), 'Expect protected variable to NOT be in job log.'
          end
        end
      end

      private

      def add_ci_variable
        create(:ci_variable, :protected, project: project, key: 'PROTECTED_VARIABLE', value: protected_value)
      end

      def create_protected_branch
        # Using default setups, which allows access for developer and maintainer
        create(:protected_branch, branch_name: 'protected-branch', project: project)
      end

      def user_commit_to_protected_branch(api_client)
        # Retry is needed due to delays with project authorization updates
        # Long term solution to accessing the status of a project authorization update
        # has been proposed in https://gitlab.com/gitlab-org/gitlab/-/issues/393369
        Support::Retrier.retry_until(
          max_duration: 60,
          sleep_interval: 1,
          message: "Commit to protected branch failed",
          retry_on_exception: true
        ) do
          create(:commit,
            api_client: api_client,
            project: project,
            branch: 'protected-branch',
            commit_message: Faker::Lorem.sentence, actions: [
              { action: 'create', file_path: Faker::File.unique.file_name, content: Faker::Lorem.sentence }
            ])
        end
      end

      def user_create_merge_request(api_client)
        # Retry is needed due to delays with project authorization updates
        # Long term solution to accessing the status of a project authorization update
        # has been proposed in https://gitlab.com/gitlab-org/gitlab/-/issues/393369
        Support::Retrier.retry_until(
          max_duration: 60,
          sleep_interval: 1,
          message: "MR fabrication failed after retry",
          retry_on_exception: true
        ) do
          create(:merge_request,
            api_client: api_client,
            project: project,
            description: Faker::Lorem.sentence,
            target_new_branch: false,
            file_name: Faker::File.unique.file_name,
            file_content: Faker::Lorem.sentence)
        end
      end

      def go_to_pipeline_job_as(user)
        Flow::Login.sign_in(as: user)
        project.visit!
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
        project.visit_job('job')
      end
    end
  end
end
