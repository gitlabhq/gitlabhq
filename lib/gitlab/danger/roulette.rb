# frozen_string_literal: true

require_relative 'teammate'

module Gitlab
  module Danger
    module Roulette
      ROULETTE_DATA_URL = 'https://about.gitlab.com/roulette.json'
      OPTIONAL_CATEGORIES = [:qa, :test].freeze

      Spin = Struct.new(:category, :reviewer, :maintainer, :optional_role)

      # Assigns GitLab team members to be reviewer and maintainer
      # for each change category that a Merge Request contains.
      #
      # @return [Array<Spin>]
      def spin(project, categories, branch_name)
        team =
          begin
            project_team(project)
          rescue => err
            warn("Reviewer roulette failed to load team data: #{err.message}")
            []
          end

        canonical_branch_name = canonical_branch_name(branch_name)

        spin_per_category = categories.each_with_object({}) do |category, memo|
          memo[category] = spin_for_category(team, project, category, canonical_branch_name)
        end

        spin_per_category.map do |category, spin|
          case category
          when :test
            if spin.reviewer.nil?
              # Fetch an already picked backend reviewer, or pick one otherwise
              spin.reviewer = spin_per_category[:backend]&.reviewer || spin_for_category(team, project, :backend, canonical_branch_name).reviewer
            end
          when :engineering_productivity
            if spin.maintainer.nil?
              # Fetch an already picked backend maintainer, or pick one otherwise
              spin.maintainer = spin_per_category[:backend]&.maintainer || spin_for_category(team, project, :backend, canonical_branch_name).maintainer
            end
          end

          spin
        end
      end

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

      def spin_role_for_category(team, role, project, category)
        team.select do |member|
          member.public_send("#{role}?", project, category, gitlab.mr_labels) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def spin_for_category(team, project, category, branch_name)
        reviewers, traintainers, maintainers =
          %i[reviewer traintainer maintainer].map do |role|
            spin_role_for_category(team, role, project, category)
          end

        # TODO: take CODEOWNERS into account?
        # https://gitlab.com/gitlab-org/gitlab/issues/26723

        # Make traintainers have triple the chance to be picked as a reviewer
        random = new_random(branch_name)
        reviewer = spin_for_person(reviewers + traintainers + traintainers, random: random)
        maintainer = spin_for_person(maintainers, random: random)

        Spin.new(category, reviewer, maintainer).tap do |spin|
          if OPTIONAL_CATEGORIES.include?(category)
            spin.optional_role = :maintainer
          end
        end
      end
    end
  end
end
