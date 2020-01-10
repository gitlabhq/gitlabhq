# frozen_string_literal: true

require 'securerandom'

module QA
  module Runtime
    module Search
      extend self
      extend Support::Api

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

          find_commit(commit, "commit*#{search_term}")
          find_project(project, "to-search*#{search_term}")
        end
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
        QA::Support::Retrier.retry_until(max_attempts: 10, sleep_interval: 10, raise_on_failure: true, retry_on_exception: true) do
          result = search(scope, search_term)
          result && result.any? { |record| yield record }
        end
      end

      def search(scope, term)
        QA::Runtime::Logger.debug("Search scope '#{scope}' for '#{term}'...")
        request = Runtime::API::Request.new(api_client, "/search?scope=#{scope}&search=#{term}")
        response = get(request.url)

        unless response.code == singleton_class::HTTP_STATUS_OK
          msg = "Search attempt failed. Request returned (#{response.code}): `#{response}`."
          QA::Runtime::Logger.debug(msg)
          raise ElasticSearchServerError, msg
        end

        parse_body(response)
      end

      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab)
      end
    end
  end
end
