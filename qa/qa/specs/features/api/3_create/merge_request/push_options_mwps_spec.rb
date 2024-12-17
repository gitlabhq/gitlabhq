# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request push options', product_group: :code_review do
      # If run locally on GDK, push options need to be enabled on the host with the following command:
      #
      # git config --global receive.advertisepushoptions true

      let(:branch) { "push-options-test-#{SecureRandom.hex(8)}" }
      let(:title) { "MR push options test #{SecureRandom.hex(8)}" }
      let(:project) { create(:project, :with_readme, name: 'merge-request-push-options') }
      let!(:runner) { create(:project_runner, project: project, name: "runner-for-#{project.name}", tags: ["runner-for-#{project.name}"]) }

      after do
        runner.remove_via_api!
      end

      it 'sets merge when pipeline succeeds', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347843' do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              no-op:
                tags:
                  - "runner-for-#{project.name}"
                script: sleep 999 # Leave the pipeline pending
            YAML
          }
        ])

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = branch
          push.merge_request_push_options = {
            create: true,
            merge_when_pipeline_succeeds: true,
            title: title
          }
        end

        merge_request = project.merge_request_with_title(title)

        expect(merge_request).not_to be_nil, "There was a problem creating the merge request"

        merge_request = create(:merge_request, project: project, iid: merge_request[:iid])

        aggregate_failures do
          expect(merge_request.state).to eq('opened')
          expect(merge_request.merge_when_pipeline_succeeds).to be true
        end
      end

      it(
        'merges when pipeline succeeds',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347842',
        quarantine: {
          type: :flaky,
          issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/346425"
        }
      ) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              no-op:
                tags:
                  - "runner-for-#{project.name}"
                script: echo 'OK'
            YAML
          }
        ])

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = branch
          push.merge_request_push_options = {
            create: true,
            merge_when_pipeline_succeeds: true,
            title: title
          }
        end

        merge_request = project.merge_request_with_title(title)

        expect(merge_request).not_to be_nil, "There was a problem creating the merge request"
        expect(merge_request[:merge_when_pipeline_succeeds]).to be true

        mr = nil
        begin
          merge_request = Support::Retrier.retry_until(max_duration: 60, sleep_interval: 5, message: 'The merge request was not merged') do
            mr = create(:merge_request, project: project, iid: merge_request[:iid])

            next unless mr.state == 'merged'

            mr
          end
        rescue Support::Repeater::WaitExceededError
          QA::Runtime::Logger.debug("MR: #{mr.api_response}")

          raise
        end

        expect(merge_request.state).to eq('merged')
      end
    end
  end
end
