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
        runners_list = runner.runners_list
        expect(runners_list.size).to eq(1)
        expect(runners_list.first[:description]).to eq(executor)

        request = Runtime::API::Request.new(api_client, "runners/#{runner.id}")
        response = delete(request.url)
        expect(response.code).to eq(Support::API::HTTP_STATUS_NO_CONTENT)
        expect(response.body).to be_empty

        expect(runner).to be_not_found_by_tags
      end
    end
  end
end
