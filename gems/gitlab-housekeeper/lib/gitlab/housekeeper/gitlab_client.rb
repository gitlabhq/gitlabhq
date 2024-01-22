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

      # This looks at the system notes of the merge request to detect if it has been updated by anyone other than the
      # current housekeeper user. If it has then it assumes that they did this for a reason and we can skip updating
      # this detail of the merge request. Otherwise we assume we should generate it again using the latest output.
      def non_housekeeper_changes(
        source_project_id:,
        source_branch:,
        target_branch:,
        target_project_id:
      )

        iid = get_existing_merge_request(
          source_project_id: source_project_id,
          source_branch: source_branch,
          target_branch: target_branch,
          target_project_id: target_project_id
        )

        return [] if iid.nil?

        merge_request_notes = get_merge_request_notes(target_project_id: target_project_id, iid: iid)

        changes = Set.new

        merge_request_notes.each do |note|
          next false unless note["system"]
          next false if note["author"]["id"] == current_user_id

          changes << :title if note['body'].start_with?("changed title from")
          changes << :description if note['body'] == "changed the description"
          changes << :code if note['body'].match?(/added \d+ commit/)
        end

        resource_label_events = get_merge_request_resource_label_events(target_project_id: target_project_id, iid: iid)

        resource_label_events.each do |event|
          next if event["user"]["id"] == current_user_id

          # Labels are routinely added by both humans and bots, so addition events aren't cause for concern.
          # However, if labels have been removed it may mean housekeeper added an incorrect label, and we shouldn't
          # re-add them.
          #
          # TODO: Inspect the actual labels housekeeper wants to add, and add if they haven't previously been removed.
          changes << :labels if event["action"] == "remove"
        end

        changes.to_a
      end

      def create_or_update_merge_request(
        source_project_id:,
        title:,
        description:,
        labels:,
        source_branch:,
        target_branch:,
        target_project_id:,
        update_title:,
        update_description:,
        update_labels:
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
            labels: labels,
            target_project_id: target_project_id,
            update_title: update_title,
            update_description: update_description,
            update_labels: update_labels
          )
        else
          create_merge_request(
            source_project_id: source_project_id,
            title: title,
            description: description,
            labels: labels,
            source_branch: source_branch,
            target_branch: target_branch,
            target_project_id: target_project_id
          )
        end
      end

      private

      def get_merge_request_notes(target_project_id:, iid:)
        response = HTTParty.get(
          "#{@base_uri}/projects/#{target_project_id}/merge_requests/#{iid}/notes",
          query: {
            per_page: 100
          },
          headers: {
            "Private-Token" => @token
          }
        )

        unless (200..299).cover?(response.code)
          raise Error,
            "Failed to get merge request notes with response code: #{response.code} and body:\n#{response.body}"
        end

        JSON.parse(response.body)
      end

      def get_merge_request_resource_label_events(target_project_id:, iid:)
        response = HTTParty.get(
          "#{@base_uri}/projects/#{target_project_id}/merge_requests/#{iid}/resource_label_events",
          query: {
            per_page: 100
          },
          headers: {
            "Private-Token" => @token
          }
        )

        unless (200..299).cover?(response.code)
          raise Error,
            "Failed to get merge request label events with response code: #{response.code} and body:\n#{response.body}"
        end

        JSON.parse(response.body)
      end

      def current_user_id
        @current_user_id = begin
          response = HTTParty.get(
            "#{@base_uri}/user",
            headers: {
              "Private-Token" => @token
            }
          )

          unless (200..299).cover?(response.code)
            raise Error,
              "Failed with response code: #{response.code} and body:\n#{response.body}"
          end

          data = JSON.parse(response.body)
          data['id']
        end
      end

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
        source_project_id:,
        title:,
        description:,
        labels:,
        source_branch:,
        target_branch:,
        target_project_id:
      )
        response = HTTParty.post("#{@base_uri}/projects/#{source_project_id}/merge_requests", body: {
          title: title,
          description: description,
          labels: Array(labels).join(','),
          source_branch: source_branch,
          target_branch: target_branch,
          target_project_id: target_project_id,
          remove_source_branch: true
        }.to_json,
          headers: {
            'Private-Token' => @token,
            'Content-Type' => 'application/json'
          })

        return if (200..299).cover?(response.code)

        raise Error,
          "Failed with response code: #{response.code} and body:\n#{response.body}"
      end

      def update_existing_merge_request(
        existing_iid:,
        title:,
        description:,
        labels:,
        target_project_id:,
        update_title:,
        update_description:,
        update_labels:
      )
        body = {}

        body[:title] = title if update_title
        body[:description] = description if update_description
        body[:add_labels] = Array(labels).join(',') if update_labels

        return if body.empty?

        response = HTTParty.put("#{@base_uri}/projects/#{target_project_id}/merge_requests/#{existing_iid}",
          body: body.to_json,
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
