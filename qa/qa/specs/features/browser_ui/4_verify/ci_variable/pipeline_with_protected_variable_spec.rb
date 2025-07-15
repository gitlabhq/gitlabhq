# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :requires_admin, product_group: :pipeline_authoring do
    describe 'Pipeline with protected variable' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:protected_value) { Faker::Alphanumeric.alphanumeric(number: 8) }
      let(:project_name) { "project-with-ci-vars#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: project_name, description: 'project with CI vars') }
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
                script: echo $PROTECTED_VARIABLE && echo "Is branch protected? $CI_COMMIT_REF_PROTECTED"
            YAML
          }
        ])
      end

      let(:protected_branch) { "protected-branch-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:unprotected_branch) { "unprotected-branch-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
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
        [developer, maintainer].each do |user|
          branch = "#{protected_branch}-#{user.id}"
          create_protected_branch(branch_name: branch)
          user_commit_to_protected_branch(user.api_client, branch: branch)
          go_to_pipeline_job_as(user, source_branch: branch)
          Page::Project::Job::Show.perform do |show|
            show.wait_until(max_duration: 10) { show.output.present? }
            expect(show.output).to have_content(protected_value), 'Expect protected variable to be in job log.'
          end
        end
      end

      it 'does not expose variable on unprotected branch', :smoke,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347664' do
        [developer, maintainer].each do |user|
          branch = "#{unprotected_branch}-#{user.id}"
          user_create_merge_request(user.api_client, source_branch: branch)
          go_to_pipeline_job_as(user, source_branch: branch)
          Page::Project::Job::Show.perform do |show|
            show.wait_until(max_duration: 10) { show.output.present? }
            expect(show.output).to have_no_content(protected_value), 'Expect protected variable to NOT be in job log.'
          end
        end
      end

      private

      def add_ci_variable
        create(:ci_variable, :protected, project: project, key: 'PROTECTED_VARIABLE', value: protected_value)
      end

      def create_protected_branch(branch_name:)
        # Using default setups, which allows access for developer and maintainer
        protected_branch = create(:protected_branch, branch_name: branch_name, project: project)

        # Wait for the protected branch to be fully effective
        Support::Retrier.retry_until(
          max_duration: 60,
          sleep_interval: 2,
          message: "Waiting for protected branch #{branch_name} to be effective"
        ) do
          project.protected_branches.find { |pb| pb[:name] == branch_name }.present?
        end

        protected_branch
      end

      def user_commit_to_protected_branch(api_client, branch:)
        # Retry is needed due to delays with project authorization updates
        # Long term solution to accessing the status of a project authorization update
        # has been proposed in https://gitlab.com/gitlab-org/gitlab/-/issues/393369
        Support::Retrier.retry_until(
          max_duration: 120,
          sleep_interval: 2,
          message: "Commit to protected branch failed",
          retry_on_exception: true
        ) do
          create(:commit,
            api_client: api_client,
            project: project,
            branch: branch,
            commit_message: Faker::Lorem.sentence, actions: [
              { action: 'create', file_path: Faker::File.unique.file_name, content: Faker::Lorem.sentence }
            ])
        end
      end

      def user_create_merge_request(api_client, source_branch:)
        # Retry is needed due to delays with project authorization updates
        # Long term solution to accessing the status of a project authorization update
        # has been proposed in https://gitlab.com/gitlab-org/gitlab/-/issues/393369
        Support::Retrier.retry_until(
          max_duration: 120,
          sleep_interval: 2,
          message: "MR fabrication failed after retry",
          retry_on_exception: true
        ) do
          create(:merge_request,
            api_client: api_client,
            project: project,
            description: Faker::Lorem.sentence,
            source_branch: source_branch,
            target_new_branch: false,
            file_name: Faker::File.unique.file_name,
            file_content: Faker::Lorem.sentence)
        end
      end

      def go_to_pipeline_job_as(user, source_branch:)
        Flow::Login.sign_in(as: user)
        project.visit!
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_pipeline_to_have_status_by_source_branch(project: project,
          source_branch: source_branch,
          status: 'success')
        project.visit_job('job')
        sleep 2
      end
    end
  end
end
