# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution,
    quarantine: {
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/411510',
      type: :flaky
    } do
    context 'when pipeline is blocked' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: 'project-with-blocked-pipeline') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      let!(:ci_file) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              test_blocked_pipeline:
                stage: build
                tags: [#{executor}]
                script: echo 'OK!'

              manual_job:
                stage: test
                needs: [test_blocked_pipeline]
                script: echo do not click me
                when: manual
                allow_failure: false

              dummy_job:
                stage: deploy
                needs: [manual_job]
                script: echo nothing
            YAML
          }
        ])
      end

      let(:merge_request) do
        create(:merge_request,
          project: project,
          description: Faker::Lorem.sentence,
          target_new_branch: false,
          file_name: 'custom_file.txt',
          file_content: Faker::Lorem.sentence)
      end

      before do
        Flow::Login.sign_in
        merge_request.visit!
      end

      after do
        runner.remove_via_api!
      end

      it 'can still merge MR successfully', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348080' do
        Page::MergeRequest::Show.perform do |show|
          # waiting for manual action status shows status badge 'blocked' on pipelines page
          show.has_pipeline_status?('waiting for manual action')
          show.merge!

          expect(show).to be_merged
        end
      end
    end
  end
end
