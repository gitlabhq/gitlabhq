# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :runner, product_group: :code_review do
    describe 'Merge request' do
      shared_examples 'set to auto-merge' do |repeat: 1|
        let(:runner_name) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
        let(:project) { create(:project, :with_readme, name: 'set-to-auto-merge') }
        let!(:runner) { create(:project_runner, project: project, name: runner_name, tags: [runner_name]) }

        let!(:ci_file) do
          create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
            {
              action: 'create',
              file_path: '.gitlab-ci.yml',
              content: <<~YAML
                test:
                  tags: ["#{runner_name}"]
                  script: sleep 15
                  only:
                    - merge_requests
              YAML
            }
          ])
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
            merge_request = create(:merge_request,
              project: project,
              description: Faker::Lorem.sentence,
              target_new_branch: false,
              source_branch: "mr-test-#{SecureRandom.hex(6)}-#{i + 1}")

            # Load the page so that the browser is as prepared as possible to display the pipeline in progress when we
            # start it.
            merge_request.visit!

            Page::MergeRequest::Show.perform do |mr|
              # Part of the challenge with this test is that the MR widget has many components that could be displayed
              # and many errors states that those components could encounter. Most of the time few of those
              # possible components will be relevant, so it would be inefficient for this test to check for each of
              # them. Instead, we fail on anything but the expected state.
              #
              # The following method allows us to handle and ignore states (as we find them) that users could safely
              # ignore.
              mr.wait_until_ready_to_merge(transient_test: transient_test)

              mr.retry_until(reload: true, message: 'Wait until ready to click Set to auto-merge') do
                # Click the Set to auto-merge button if we can
                break mr.set_to_auto_merge! if mr.has_element?('merge-button', text: 'Set to auto-merge')

                # But fail if the button is missing because the pipeline is complete
                raise "The pipeline already finished before we could set to auto-merge" if mr.wait_until do
                                                                                             project.pipelines.first
                                                                                           end[:status] == 'success'

                # Otherwise, if this is not a transient test reload the page and retry
                next false unless transient_test
              end

              aggregate_failures do
                expect { mr.merged? }.to eventually_be_truthy.within(max_duration: 120),
                  "Expected content 'The changes were merged' but it did not appear."
                expect(merge_request.reload!.merge_when_pipeline_succeeds).to be_truthy
                expect(merge_request.state).to eq('merged')
                expect(project.pipelines.last[:status]).to eq('success')
              end
            end
          end
        end
      end

      context 'when merging once', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347686' do
        it_behaves_like 'set to auto-merge'
      end

      context 'when merging several times', :transient,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347641' do
        it_behaves_like 'set to auto-merge', repeat: Runtime::Env.transient_trials
      end
    end
  end
end
