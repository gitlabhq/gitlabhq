# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :runner do
    describe 'Merge requests' do
      shared_examples 'merge when pipeline succeeds' do |repeat: 1|
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'merge-when-pipeline-succeeds'
            project.initialize_with_readme = true
          end
        end

        let!(:runner) do
          Resource::Runner.fabricate! do |runner|
            runner.project = project
            runner.name = "runner-for-#{project.name}"
            runner.tags = ["runner-for-#{project.name}"]
          end
        end

        before do
          Flow::Login.sign_in
        end

        after do
          runner&.remove_via_api!
          project&.remove_via_api!
        end

        it 'merges after pipeline succeeds' do
          transient_test = repeat > 1

          repeat.times do |i|
            QA::Runtime::Logger.info("Transient bug test - Trial #{i}") if transient_test

            branch_name = "mr-test-#{SecureRandom.hex(6)}-#{i}"

            # Create a branch that will be merged into the default branch
            Resource::Repository::ProjectPush.fabricate! do |project_push|
              project_push.project = project
              project_push.new_branch = true
              project_push.branch_name = branch_name
              project_push.file_name = "#{branch_name}.txt"
            end

            # Create a merge request to merge the branch we just created
            merge_request = Resource::MergeRequest.fabricate_via_api! do |merge_request|
              merge_request.project = project
              merge_request.source_branch = branch_name
              merge_request.no_preparation = true
            end

            # Load the page so that the browser is as prepared as possible to display the pipeline in progress when we
            # start it.
            merge_request.visit!

            # Push a new pipeline config file
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.branch = branch_name
              commit.add_files(
                [
                  {
                    file_path: '.gitlab-ci.yml',
                    content: <<~EOF
                      test:
                        tags: ["runner-for-#{project.name}"]
                        script: sleep 20
                        only:
                          - merge_requests
                    EOF
                  }
                ]
              )
            end

            Page::MergeRequest::Show.perform do |mr|
              refresh

              # Part of the challenge with this test is that the MR widget has many components that could be displayed
              # and many errors states that those components could encounter. Most of the time few of those
              # possible components will be relevant, so it would be inefficient for this test to check for each of
              # them. Instead, we fail on anything but the expected state.
              #
              # The following method allows us to handle and ignore states (as we find them) that users could safely ignore.
              mr.wait_until_ready_to_merge(transient_test: transient_test)

              mr.retry_until(reload: true, message: 'Wait until ready to click MWPS') do
                merge_request.reload!

                # Don't try to click MWPS if the MR is merged or the pipeline is complete
                break if merge_request.state == 'merged' || mr.wait_until { project.pipelines.last }[:status] == 'success'

                # Try to click MWPS if this is a transient test, or if the MWPS button is visible,
                # otherwise reload the page and retry
                next false unless transient_test || mr.has_element?(:merge_button, text: 'Merge when pipeline succeeds')

                # No need to keep retrying if we can click MWPS
                break mr.merge_when_pipeline_succeeds!
              end

              aggregate_failures do
                expect { mr.merged? }.to eventually_be_truthy.within(max_duration: 60), "Expected content 'The changes were merged' but it did not appear."
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
