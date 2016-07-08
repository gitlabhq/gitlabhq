module Gitlab
  module Import
    module Github
      class Client
        def initialize(project)
          @repo = project.import_source
          @repo_url = project.import_url
          @credentials = project.import_data.credentials
          @options = Options.new
        end

        def labels
          request { client.labels(repo, per_page: 100) }
        end

        private

        attr_reader :credentials, :options, :repo, :repo_url

        SAFE_REMAINING_REQUESTS = 100
        SAFE_SLEEP_TIME = 500

        def client
          @client ||= begin
            Octokit.auto_paginate = false

            Octokit::Client.new(
              access_token: access_token,
              api_endpoint: options.endpoint,
              connection_options: {
                ssl: { verify: options.verify_ssl }
              }
           )
          end
        end

        def access_token
          credentials[:user]
        end

        def rate_limit
          client.rate_limit!
        end

        def rate_limit_exceed?
          rate_limit.remaining <= SAFE_REMAINING_REQUESTS
        end

        def rate_limit_sleep_time
          rate_limit.resets_in + SAFE_SLEEP_TIME
        end

        def request
          sleep rate_limit_sleep_time if rate_limit_exceed?

          data = yield

          last_response = client.last_response

          while last_response.rels[:next]
            sleep rate_limit_sleep_time if rate_limit_exceed?
            last_response = last_response.rels[:next].get
            data.concat(last_response.data) if last_response.data.is_a?(Array)
          end

          data
        end
      end
    end
  end
end
