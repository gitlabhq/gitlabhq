# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, :requires_admin, product_group: :pipeline_execution do
    describe 'Pipeline configuration access keyword' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: 'project-with-artifacts', initialize_with_readme: true) }

      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }
      let!(:developer_user) { create(:user) }
      let!(:non_member_user) { create(:user) }

      let(:merge_request) do
        create(:merge_request,
          project: project,
          title: 'Add artifact access configuration')
      end

      before do
        project.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
      end

      after do
        runner.remove_via_api!
      end

      shared_examples 'artifact access' do |access_level, developer_access, non_member_access,
          member_testcase, non_member_testcase|
        before do
          commit_ci_file(access_level)
          create_mr
        end

        it "verifies artifact access for developer user with #{access_level} access", testcase: member_testcase do
          Flow::Login.sign_in(as: developer_user)

          merge_request.visit!

          Page::MergeRequest::Show.perform do |show|
            Support::Waiter.wait_until(reload_page: false) do
              show.has_pipeline_status?('passed')
            end

            if developer_access
              expect(show).to have_artifacts_dropdown
            else
              expect(show).to have_no_artifacts_dropdown
            end
          end
        end

        it "verifies artifact access for non-member user with #{access_level} access", testcase: non_member_testcase do
          Flow::Login.sign_in(as: non_member_user)

          merge_request.visit!

          Page::MergeRequest::Show.perform do |show|
            Support::Waiter.wait_until(reload_page: false) do
              show.has_pipeline_status?('passed')
            end

            if non_member_access
              expect(show).to have_artifacts_dropdown
            else
              expect(show).to have_no_artifacts_dropdown
            end
          end
        end
      end

      context 'when access is set to none' do
        it_behaves_like 'artifact access', 'none', false, false,
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/465991', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/465697'
      end

      context 'when access is set to developer' do
        it_behaves_like 'artifact access', 'developer', true, false,
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/465994', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/465995'
      end

      context 'when access is set to all' do
        it_behaves_like 'artifact access', 'all', true, true,
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/465992', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/465993'
      end

      private

      def commit_ci_file(access_level)
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              job_with_artifact:
                tags: ["#{executor}"]
                script:
                  - mkdir tmp
                  - echo "write some random string" >> tmp/#{access_level}.txt
                artifacts:
                  paths:
                    - tmp
                  access: #{access_level}
            YAML
          }
        ])
      end

      def create_mr
        merge_request
        project.visit!

        Support::Waiter.wait_until(message: 'Wait for MR pipeline to be created', max_duration: 180) do
          project.pipelines.length > 1
        end
      end
    end
  end
end
