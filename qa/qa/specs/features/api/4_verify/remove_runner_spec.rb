# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Runner removal' do
      include Support::API

      let(:api_client) { Runtime::API::Client.new(:gitlab) }
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:runner_tags) { ['runner-registration-e2e-test'] }
      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = executor
          runner.tags = runner_tags
        end
      end

      before do
        sleep 5 # Runner should register within 5 seconds
      end

      # Removing a runner via the UI is covered by `spec/features/runners_spec.rb``
      it 'removes the runner' do
        expect(runner.project.runners.size).to eq(1)
        expect(runner.project.runners.first[:description]).to eq(executor)

        request = Runtime::API::Request.new(api_client, "runners/#{runner.project.runners.first[:id]}")
        response = delete(request.url)
        expect(response.code).to eq(Support::API::HTTP_STATUS_NO_CONTENT)
        expect(response.body).to be_empty

        expect(runner.project.runners).to be_empty
      end
    end
  end
end
