# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'PostReceive idempotent', product_group: :source_code do
      # Tests that a push does not result in multiple changes from repeated PostReceive executions.
      # One of the consequences would be duplicate push events

      let(:project) { create(:project, :with_readme, name: 'push-postreceive-idempotent') }

      it 'pushes and creates a single push event three times', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347680' do
        verify_single_event_per_push(repeat: 3)
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
