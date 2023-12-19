# frozen_string_literal: true

require 'httparty'
require 'json'

module Gitlab
  module Housekeeper
    class GitlabClient
      Error = Class.new(StandardError)

      def initialize
        @token = ENV.fetch("HOUSEKEEPER_GITLAB_API_TOKEN")
        @base_uri = 'https://gitlab.com/api/v4'
      end

      def create_or_update_merge_request(
        source_project_id:,
        title:,
        description:,
        source_branch:,
        target_branch:,
        target_project_id:
      )
        existing_iid = get_existing_merge_request(
          source_project_id: source_project_id,
          source_branch: source_branch,
          target_branch: target_branch,
          target_project_id: target_project_id
        )

        if existing_iid
          update_existing_merge_request(
            existing_iid: existing_iid,
            title: title,
            description: description,
            target_project_id: target_project_id
          )
        else
          create_merge_request(
            source_project_id: source_project_id,
            title: title,
            description: description,
            source_branch: source_branch,
            target_branch: target_branch,
            target_project_id: target_project_id
          )
        end
      end

      private

      def get_existing_merge_request(source_project_id:, source_branch:, target_branch:, target_project_id:)
        response = HTTParty.get("#{@base_uri}/projects/#{target_project_id}/merge_requests",
          query: {
            state: :opened,
            source_branch: source_branch,
            target_branch: target_branch,
            source_project_id: source_project_id
          },
          headers: {
            'Private-Token' => @token
          })

        unless (200..299).cover?(response.code)
          raise Error,
            "Failed with response code: #{response.code} and body:\n#{response.body}"
        end

        data = JSON.parse(response.body)

        return nil if data.empty?

        iids = data.pluck('iid')

        raise Error, "More than one matching MR exists: iids: #{iids.join(',')}" unless data.size == 1

        iids.first
      end

      def create_merge_request(
        source_project_id:, title:, description:, source_branch:, target_branch:,
        target_project_id:)
        response = HTTParty.post("#{@base_uri}/projects/#{source_project_id}/merge_requests", body: {
          title: title,
          description: description,
          source_branch: source_branch,
          target_branch: target_branch,
          target_project_id: target_project_id
        }.to_json,
          headers: {
            'Private-Token' => @token,
            'Content-Type' => 'application/json'
          })

        return if (200..299).cover?(response.code)

        raise Error,
          "Failed with response code: #{response.code} and body:\n#{response.body}"
      end

      def update_existing_merge_request(existing_iid:, title:, description:, target_project_id:)
        response = HTTParty.put("#{@base_uri}/projects/#{target_project_id}/merge_requests/#{existing_iid}", body: {
          title: title,
          description: description
        }.to_json,
          headers: {
            'Private-Token' => @token,
            'Content-Type' => 'application/json'
          })

        return if (200..299).cover?(response.code)

        raise Error,
          "Failed with response code: #{response.code} and body:\n#{response.body}"
      end
    end
  end
end
