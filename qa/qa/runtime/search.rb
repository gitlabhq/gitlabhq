# frozen_string_literal: true

module QA
  module Runtime
    module Search
      extend self
      extend Support::API

      RETRY_MAX_ITERATION = 10
      RETRY_SLEEP_INTERVAL = 12
      INSERT_RECALL_THRESHOLD = RETRY_MAX_ITERATION * RETRY_SLEEP_INTERVAL

      ElasticSearchServerError = Class.new(RuntimeError)

      def assert_elasticsearch_responding
        QA::Runtime::Logger.debug("Attempting to search via Elasticsearch...")

        QA::Support::Retrier.retry_on_exception(max_attempts: 3) do
          search_term = SecureRandom.hex(8)

          QA::Runtime::Logger.debug("Creating commit and project including search term '#{search_term}'...")

          content = "Elasticsearch test commit #{search_term}"
          project = Resource::Project.fabricate_via_api! do |project|
            project.name = "project-to-search-#{search_term}"
          end
          commit = Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = content
            commit.add_files(
              [
                {
                  file_path: 'test.txt',
                  content: content
                }
              ]
            )
          end

          verify_search_engine_ok(search_term)

          find_commit(commit, "commit*#{search_term}")
          find_project(project, "to-search*#{search_term}")
        end
      end

      def elasticsearch_on?(api_client)
        elasticsearch_state_request = Runtime::API::Request.new(api_client, '/application/settings')
        response = get elasticsearch_state_request.url

        parse_body(response)[:elasticsearch_search] && parse_body(response)[:elasticsearch_indexing]
      end

      def disable_elasticsearch(api_client)
        disable_elasticsearch_request = Runtime::API::Request.new(api_client, '/application/settings')
        put disable_elasticsearch_request.url, elasticsearch_search: false, elasticsearch_indexing: false
      end

      def create_search_request(api_client, scope, search_term)
        Runtime::API::Request.new(api_client, '/search', scope: scope, search: search_term)
      end

      def find_code(file_name, search_term)
        find_target_in_scope('blobs', search_term) do |record|
          record[:filename] == file_name && record[:data].include?(search_term)
        end

        QA::Runtime::Logger.debug("Found file '#{file_name} containing code '#{search_term}'")
      end

      def find_commit(commit, search_term)
        find_target_in_scope('commits', search_term) do |record|
          record[:message] == commit.commit_message
        end

        QA::Runtime::Logger.debug("Found commit '#{commit.commit_message} (#{commit.short_id})' via '#{search_term}'")
      end

      def find_project(project, search_term)
        find_target_in_scope('projects', search_term) do |record|
          record[:name] == project.name
        end

        QA::Runtime::Logger.debug("Found project '#{project.name}' via '#{search_term}'")
      end

      private

      def find_target_in_scope(scope, search_term)
        QA::Support::Retrier.retry_until(max_attempts: RETRY_MAX_ITERATION, sleep_interval: RETRY_SLEEP_INTERVAL, raise_on_failure: true, retry_on_exception: true) do
          result = search(scope, search_term)
          result && result.any? { |record| yield record }
        end
      end

      def search(scope, term)
        response = get_response(scope, term)

        unless response.code == singleton_class::HTTP_STATUS_OK
          msg = "Search attempt failed. Request returned (#{response.code}): `#{response}`."
          QA::Runtime::Logger.debug(msg)
          raise ElasticSearchServerError, msg
        end

        parse_body(response)
      end

      def get_response(scope, term)
        QA::Runtime::Logger.debug("Search scope '#{scope}' for '#{term}'...")
        request = Runtime::API::Request.new(api_client, "/search?scope=#{scope}&search=#{term}")
        get(request.url)
      end

      def verify_search_engine_ok(search_term)
        response = get_response('commits', search_term)
        if /5[0-9][0-9]/.match?(response.code.to_s)
          raise ElasticSearchServerError, "elasticsearch attempt returned code #{response.code}. Check that search was conducted on the appropriate url and port."
        end
      end

      def api_client
        Runtime::User::Store.user_api_client
      end
    end
  end
end
