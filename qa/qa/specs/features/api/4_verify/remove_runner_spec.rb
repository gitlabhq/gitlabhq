# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :runner do
    describe 'Runner removal' do
      include Support::API

      let(:api_client) { Runtime::API::Client.new(:gitlab) }
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:runner_tags) { ["runner-registration-e2e-test-#{Faker::Alphanumeric.alphanumeric(number: 8)}"] }
      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = executor
          runner.tags = runner_tags
        end
      end

      # Removing a runner via the UI is covered by `spec/features/runners_spec.rb``
      it 'removes the runner', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354828' do
        runners = nil
        expect { (runners = runner.list_of_runners(tag_list: runner_tags)).size }
          .to eventually_eq(1).within(max_duration: 10, sleep_interval: 1)
        expect(runners.first[:description]).to eq(executor)

        request = Runtime::API::Request.new(api_client, "runners/#{runners.first[:id]}")
        response = delete(request.url)
        expect(response.code).to eq(Support::API::HTTP_STATUS_NO_CONTENT)
        expect(response.body).to be_empty

        expect(runner.list_of_runners(tag_list: runner_tags)).to be_empty
      end
    end
  end
end
