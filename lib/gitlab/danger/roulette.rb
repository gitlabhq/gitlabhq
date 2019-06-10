# frozen_string_literal: true

require 'net/http'
require 'json'
require 'cgi'

require_relative 'teammate'

module Gitlab
  module Danger
    module Roulette
      ROULETTE_DATA_URL = 'https://about.gitlab.com/roulette.json'
      HTTPError = Class.new(RuntimeError)

      # Looks up the current list of GitLab team members and parses it into a
      # useful form
      #
      # @return [Array<Teammate>]
      def team
        @team ||=
          begin
            data = http_get_json(ROULETTE_DATA_URL)
            data.map { |hash| ::Gitlab::Danger::Teammate.new(hash) }
          rescue JSON::ParserError
            raise "Failed to parse JSON response from #{ROULETTE_DATA_URL}"
          end
      end

      # Like +team+, but only returns teammates in the current project, based on
      # project_name.
      #
      # @return [Array<Teammate>]
      def project_team(project_name)
        team.select { |member| member.in_project?(project_name) }
      end

      def canonical_branch_name(branch_name)
        branch_name.gsub(/^[ce]e-|-[ce]e$/, '')
      end

      def new_random(seed)
        Random.new(Digest::MD5.hexdigest(seed).to_i(16))
      end

      # Known issue: If someone is rejected due to OOO, and then becomes not OOO, the
      # selection will change on next spin
      def spin_for_person(people, random:)
        person = nil
        people = people.dup

        people.size.times do
          person = people.sample(random: random)

          break person unless out_of_office?(person)

          people -= [person]
        end

        person
      end

      private

      def out_of_office?(person)
        username = CGI.escape(person.username)
        api_endpoint = "https://gitlab.com/api/v4/users/#{username}/status"
        response = http_get_json(api_endpoint)
        response["message"]&.match?(/OOO/i)
      rescue HTTPError, JSON::ParserError
        false # this is no worse than not checking for OOO
      end

      def http_get_json(url)
        rsp = Net::HTTP.get_response(URI.parse(url))

        unless rsp.is_a?(Net::HTTPSuccess)
          raise HTTPError, "Failed to read #{url}: #{rsp.code} #{rsp.message}"
        end

        JSON.parse(rsp.body)
      end
    end
  end
end
