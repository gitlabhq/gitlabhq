# frozen_string_literal: true

module QA
  RSpec.describe 'GitLab Metrics', :aggregate_failures, :orchestrated, :metrics, product_group: :observability do
    let(:web_uri) { URI.parse(Runtime::Scenario.gitlab_address) }
    let(:endpoint) do
      "#{web_uri.scheme}://#{web_uri.host}:#{port}#{path}"
    end

    let(:response) { RestClient.get(endpoint) }

    describe 'Web metrics' do
      describe 'via Rails controller endpoint' do
        let(:port) { web_uri.port }
        let(:path) { '/-/metrics' }

        it 'returns 200 OK and serves metrics',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/362911' do
          # This does not currently work because it requires a special auth token to
          # make an internal endpoint request. But we should probably test this, too.
          skip
        end
      end

      describe 'via dedicated server' do
        let(:port) { '8083' }
        let(:path) { '/metrics' }

        it 'returns 200 OK and serves metrics',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/362912' do
          expect(response.code).to be(200)
          expect(response.body).to match(/^puma_/)
        end
      end
    end

    describe 'Sidekiq metrics' do
      describe 'via dedicated server' do
        let(:port) { '8082' }
        let(:path) { '/metrics' }

        it 'returns 200 OK and serves metrics',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/362913' do
          expect(response.code).to be(200)
          expect(response.body).to match(/^sidekiq_/)
        end
      end
    end
  end
end
