# frozen_string_literal: true

require_relative 'teammate'
require_relative 'request_helper' unless defined?(Gitlab::Danger::RequestHelper)

module Gitlab
  module Danger
    module Roulette
      ROULETTE_DATA_URL = 'https://gitlab-org.gitlab.io/gitlab-roulette/roulette.json'
      HOURS_WHEN_PERSON_CAN_BE_PICKED = (6..14).freeze

      INCLUDE_TIMEZONE_FOR_CATEGORY = {
        database: false
      }.freeze

      Spin = Struct.new(:category, :reviewer, :maintainer, :optional_role, :timezone_experiment)

      def team_mr_author
        team.find { |person| person.username == mr_author_username }
      end

      # Assigns GitLab team members to be reviewer and maintainer
      # for each change category that a Merge Request contains.
      #
      # @return [Array<Spin>]
      def spin(project, categories, timezone_experiment: false)
        spins = categories.sort.map do |category|
          including_timezone = INCLUDE_TIMEZONE_FOR_CATEGORY.fetch(category, timezone_experiment)

          spin_for_category(project, category, timezone_experiment: including_timezone)
        end

        backend_spin = spins.find { |spin| spin.category == :backend }

        spins.each do |spin|
          including_timezone = INCLUDE_TIMEZONE_FOR_CATEGORY.fetch(spin.category, timezone_experiment)
          case spin.category
          when :qa
            # MR includes QA changes, but also other changes, and author isn't an SET
            if categories.size > 1 && !team_mr_author&.reviewer?(project, spin.category, [])
              spin.optional_role = :maintainer
            end
          when :test
            spin.optional_role = :maintainer

            if spin.reviewer.nil?
              # Fetch an already picked backend reviewer, or pick one otherwise
              spin.reviewer = backend_spin&.reviewer || spin_for_category(project, :backend, timezone_experiment: including_timezone).reviewer
            end
          when :engineering_productivity
            if spin.maintainer.nil?
              # Fetch an already picked backend maintainer, or pick one otherwise
              spin.maintainer = backend_spin&.maintainer || spin_for_category(project, :backend, timezone_experiment: including_timezone).maintainer
            end
          when :ci_template
            if spin.maintainer.nil?
              # Fetch an already picked backend maintainer, or pick one otherwise
              spin.maintainer = backend_spin&.maintainer || spin_for_category(project, :backend, timezone_experiment: including_timezone).maintainer
            end
          end
        end

        spins
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
      rescue => err
        warn("Reviewer roulette failed to load team data: #{err.message}")
        []
      end

      # Known issue: If someone is rejected due to OOO, and then becomes not OOO, the
      # selection will change on next spin
      # @param [Array<Teammate>] people
      def spin_for_person(people, random:, timezone_experiment: false)
        shuffled_people = people.shuffle(random: random)

        if timezone_experiment
          shuffled_people.find(&method(:valid_person_with_timezone?))
        else
          shuffled_people.find(&method(:valid_person?))
        end
      end

      private

      # @param [Teammate] person
      # @return [Boolean]
      def valid_person?(person)
        !mr_author?(person) && person.available
      end

      # @param [Teammate] person
      # @return [Boolean]
      def valid_person_with_timezone?(person)
        valid_person?(person) && HOURS_WHEN_PERSON_CAN_BE_PICKED.cover?(person.local_hour)
      end

      # @param [Teammate] person
      # @return [Boolean]
      def mr_author?(person)
        person.username == mr_author_username
      end

      def mr_author_username
        helper.gitlab_helper&.mr_author || `whoami`
      end

      def mr_source_branch
        return `git rev-parse --abbrev-ref HEAD` unless helper.gitlab_helper&.mr_json

        helper.gitlab_helper.mr_json['source_branch']
      end

      def mr_labels
        helper.gitlab_helper&.mr_labels || []
      end

      def new_random(seed)
        Random.new(Digest::MD5.hexdigest(seed).to_i(16))
      end

      def spin_role_for_category(team, role, project, category)
        team.select do |member|
          member.public_send("#{role}?", project, category, mr_labels) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def spin_for_category(project, category, timezone_experiment: false)
        team = project_team(project)
        reviewers, traintainers, maintainers =
          %i[reviewer traintainer maintainer].map do |role|
            spin_role_for_category(team, role, project, category)
          end
        hungry_reviewers = reviewers.select { |member| member.hungry }
        hungry_traintainers = traintainers.select { |member| member.hungry }

        # TODO: take CODEOWNERS into account?
        # https://gitlab.com/gitlab-org/gitlab/issues/26723

        random = new_random(mr_source_branch)

        # Make hungry traintainers have 4x the chance to be picked as a reviewer
        # Make traintainers have 3x the chance to be picked as a reviewer
        # Make hungry reviewers have 2x the chance to be picked as a reviewer
        weighted_reviewers = reviewers + hungry_reviewers + traintainers + traintainers + traintainers + hungry_traintainers
        reviewer = spin_for_person(weighted_reviewers, random: random, timezone_experiment: timezone_experiment)
        maintainer = spin_for_person(maintainers, random: random, timezone_experiment: timezone_experiment)

        Spin.new(category, reviewer, maintainer, false, timezone_experiment)
      end
    end
  end
end
