# frozen_string_literal: true

module QA
  module Tools
    class DeleteResourceBase
      include Support::API
      include Lib::Project
      include Lib::Group
      include Ci::Helpers

      SANDBOX_GROUPS = %w[gitlab-qa-sandbox-group
        gitlab-qa-sandbox-group-0
        gitlab-qa-sandbox-group-1
        gitlab-qa-sandbox-group-2
        gitlab-qa-sandbox-group-3
        gitlab-qa-sandbox-group-4
        gitlab-qa-sandbox-group-5
        gitlab-qa-sandbox-group-6
        gitlab-qa-sandbox-group-7].freeze

      def initialize(delete_before: (Date.today - 3).to_s, dry_run: false)
        %w[GITLAB_ADDRESS GITLAB_QA_ACCESS_TOKEN].each do |var|
          raise ArgumentError, "Please provide #{var} environment variable" unless ENV[var]
        end

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @delete_before = Date.parse(delete_before)
        @dry_run = dry_run
        @failed_deletion_attempts = []
      end

      def user_api_client(token)
        Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: token)
      end
    end
  end
end
