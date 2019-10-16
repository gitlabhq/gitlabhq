# frozen_string_literal: true

require_relative 'teammate'

module Gitlab
  module Danger
    module Roulette
      ROULETTE_DATA_URL = 'https://about.gitlab.com/roulette.json'

      # Looks up the current list of GitLab team members and parses it into a
      # useful form
      #
      # @return [Array<Teammate>]
      def team
        @team ||=
          begin
            data = Gitlab::Danger::RequestHelper.http_get_json(ROULETTE_DATA_URL)
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
      # @param [Array<Teammate>] people
      def spin_for_person(people, random:)
        people.shuffle(random: random)
          .find(&method(:valid_person?))
      end

      private

      # @param [Teammate] person
      # @return [Boolean]
      def valid_person?(person)
        !mr_author?(person) && person.available?
      end

      # @param [Teammate] person
      # @return [Boolean]
      def mr_author?(person)
        person.username == gitlab.mr_author
      end
    end
  end
end
