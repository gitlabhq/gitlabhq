# frozen_string_literal: true

require 'airborne'

module QA
  # This test ensures that the version described by the `DEPLOY_VERSION`
  # environment variable is the version actually running.
  #
  # See https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/1179
  RSpec.describe 'Version sanity check', :smoke, only: { pipeline: [:pre, :release] } do
    let(:api_client) { Runtime::API::Client.new(:gitlab) }
    let(:request) { Runtime::API::Request.new(api_client, '/version') }

    it 'is the specified version' do
      # The `DEPLOY_VERSION` variable will only be provided for deploys to the
      # `pre` and `release` environments, which only receive packaged releases.
      #
      # For these releases, `deploy_version` will be a package string (e.g.,
      # `13.1.3-ee.0`), and the reported version will be something like
      # `13.1.3-ee`, so we only compare the leading SemVer string.
      #
      # | Package          | Version        |
      # | ---------------- | -------------- |
      # | 13.3.5-ee.0      | 13.3.5-ee      |
      # | 13.3.0-rc42.ee.0 | 13.3.0-rc42-ee |
      deploy = Runtime::Env.deploy_version&.gsub(/\A(\d+\.\d+\.\d+).*\z/, '\1')

      skip('No deploy version provided') if deploy.nil? || deploy.empty?

      get request.url

      expect_status(200)
      expect(json_body).to have_key(:version)
      expect(json_body[:version]).to start_with(deploy)
    end
  end
end
