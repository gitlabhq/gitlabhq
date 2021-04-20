# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'PostReceive idempotent' do
      # Tests that a push does not result in multiple changes from repeated PostReceive executions.
      # One of the consequences would be duplicate push events

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'push-postreceive-idempotent'
          project.initialize_with_readme = true
        end
      end

      after do
        project&.remove_via_api!
      end

      it 'pushes and creates a single push event three times', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1744' do
        verify_single_event_per_push(repeat: 3)
      end

      it 'repeatedly pushes and creates a single push event several times', :transient, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1744' do
        verify_single_event_per_push(repeat: Runtime::Env.transient_trials) do |i|
          QA::Runtime::Logger.info("Transient bug test action - Trial #{i}")
        end
      end

      def verify_single_event_per_push(repeat:)
        repeat.times do |i|
          yield i if block_given?

          commit_message = "test post-receive idempotency #{SecureRandom.hex(8)}"

          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.new_branch = false
            push.commit_message = commit_message
          end

          events = project.push_events(commit_message)

          aggregate_failures do
            expect(events.size).to eq(1), "An unexpected number of push events was created"
            expect(events.first.dig(:push_data, :commit_title)).to eq(commit_message)
          end
        end
      end
    end
  end
end
