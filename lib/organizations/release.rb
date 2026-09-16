# frozen_string_literal: true

module Organizations
  # The Organizations release layer: an organization feature is enabled or
  # disabled based on its stage.
  # See doc/development/organizations/release_process.md.
  module Release
    UnknownFlagError = Class.new(StandardError)
    UnknownStageError = Class.new(StandardError)

    # Stages are cumulative: Experimental and Beta cascade forward, so a feature
    # at any later stage is also enabled for their audiences (an LA feature is on
    # for Experimental and Beta too). LA percentages don't nest and GA is on for
    # everyone, so neither is a cascade source. Earliest-first; order matters.
    CASCADING_STAGE_KEYS = %i[experimental beta].freeze

    class << self
      # True when the actor has the feature's stage flag enabled, or an earlier
      # cascading stage flag (see CASCADING_STAGE_KEYS).
      #
      # Pass nil for the instance-wide check. Use one actor type per flag
      # everywhere: the stage flags split percentage rollouts by actor type.
      #
      # org_stage_#{key} is built inline so the feature-flag usage scanner sees
      # the whole family. See scripts/feature_flags/used-feature-flags.
      def enabled?(flag, actor)
        stage = registry.find(flag).stage

        stage_keys_to_check(stage).any? do |key|
          # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- interpolated by design; suffix is a stage key from Stage::ALL
          Feature.enabled?(:"org_stage_#{key}", actor)
          # rubocop:enable Gitlab/FeatureFlagKeyDynamic
        end
      end

      # Real per-user "has this actor adopted organizations" state, not a flag rollout
      # check. `flag:` additionally requires that flag be enabled for the user first --
      # self-managed/Dedicated (no legacy default org to leave) enroll only via a flag.
      def enrolled?(user, flag: nil)
        return false if flag && !enabled?(flag, user)

        if Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- use Gitlab.com? for now to keep simple. May refactor to SaaS feature in the future
          user.has_active_non_default_organization?
        else
          flag.present?
        end
      end

      def stages
        Stage::ALL
      end

      private

      # The flag's own stage plus any earlier cascading stages. GA checks only itself.
      def stage_keys_to_check(stage)
        return [stage.key] if stage.key == :ga

        earlier = CASCADING_STAGE_KEYS.take_while { |key| key != stage.key }

        earlier + [stage.key]
      end

      def registry
        Registry.instance
      end
    end
  end
end
