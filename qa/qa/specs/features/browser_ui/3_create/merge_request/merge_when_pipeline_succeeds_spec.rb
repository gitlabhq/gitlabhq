# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :runner, product_group: :code_review do
    describe 'Merge requests' do
      shared_examples 'merge when pipeline succeeds' do |repeat: 1|
        let(:runner_name) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'merge-when-pipeline-succeeds'
            project.initialize_with_readme = true
          end
        end

        let!(:runner) do
          Resource::ProjectRunner.fabricate! do |runner|
            runner.project = project
            runner.name = runner_name
            runner.tags = [runner_name]
          end
        end

        let!(:ci_file) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files(
              [
                {
                  file_path: '.gitlab-ci.yml',
                  content: <<~YAML
                    test:
                      tags: ["#{runner_name}"]
                      script: sleep 15
                      only:
                        - merge_requests
                  YAML
                }
              ]
            )
          end
        end

        before do
          Flow::Login.sign_in
        end

        after do
          runner&.remove_via_api!
        end

        it 'merges after pipeline succeeds', quarantine: {
          type: :flaky,
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/403017'
        } do
          transient_test = repeat > 1

          repeat.times do |i|
            QA::Runtime::Logger.info("Transient bug test - Trial #{i + 1}") if transient_test

            # Create a merge request to trigger pipeline
            merge_request = Resource::MergeRequest.fabricate_via_api! do |merge_request|
              merge_request.project = project
              merge_request.description = Faker::Lorem.sentence
              merge_request.target_new_branch = false
              merge_request.source_branch = "mr-test-#{SecureRandom.hex(6)}-#{i + 1}"
            end

            # Load the page so that the browser is as prepared as possible to display the pipeline in progress when we
            # start it.
            merge_request.visit!

            Page::MergeRequest::Show.perform do |mr|
              # Part of the challenge with this test is that the MR widget has many components that could be displayed
              # and many errors states that those components could encounter. Most of the time few of those
              # possible components will be relevant, so it would be inefficient for this test to check for each of
              # them. Instead, we fail on anything but the expected state.
              #
              # The following method allows us to handle and ignore states (as we find them) that users could safely ignore.
              mr.wait_until_ready_to_merge(transient_test: transient_test)

              mr.retry_until(reload: true, message: 'Wait until ready to click MWPS') do
                # Click the MWPS button if we can
                break mr.merge_when_pipeline_succeeds! if mr.has_element?(:merge_button, text: 'Merge when pipeline succeeds')

                # But fail if the button is missing because the pipeline is complete
                raise "The pipeline already finished before we could click MWPS" if mr.wait_until { project.pipelines.first }[:status] == 'success'

                # Otherwise, if this is not a transient test reload the page and retry
                next false unless transient_test
              end

              aggregate_failures do
                expect { mr.merged? }.to eventually_be_truthy.within(max_duration: 120), "Expected content 'The changes were merged' but it did not appear."
                expect(merge_request.reload!.merge_when_pipeline_succeeds).to be_truthy
                expect(merge_request.state).to eq('merged')
                expect(project.pipelines.last[:status]).to eq('success')
              end
            end
          end
        end
      end

      context 'when merging once', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347686' do
        it_behaves_like 'merge when pipeline succeeds'
      end

      context 'when merging several times', :transient, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347641' do
        it_behaves_like 'merge when pipeline succeeds', repeat: Runtime::Env.transient_trials
      end
    end
  end
end
