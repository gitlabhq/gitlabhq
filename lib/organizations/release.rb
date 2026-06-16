# frozen_string_literal: true

module Organizations
  # The Organizations release layer: feature code asks whether an organization
  # flag is enabled, and the flag's stage (config/organizations_release.yml)
  # decides which shared org_stage_* flag gates it.
  module Release
    UnknownFlagError = Class.new(StandardError)
    UnknownStageError = Class.new(StandardError)

    class << self
      # The actor is passed straight to the stage flag; pass nil for the
      # instance-wide gate. Use a consistent actor type per flag -- the shared
      # stage flags bucket by type for percentage rollouts.
      def enabled?(flag, actor)
        flag = registry.find(flag)

        stage_flag_enabled?(flag, actor)
      end

      def stages
        Stage::ALL
      end

      private

      # Built inline as an interpolated literal so the feature-flag usage check
      # tracks the whole org_stage_* family; it can't resolve a bare variable.
      # See scripts/feature_flags/used-feature-flags.
      def stage_flag_enabled?(flag, actor)
        # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- interpolated by design; suffix is a stage key from Stage::ALL
        Feature.enabled?(:"org_stage_#{flag.stage.key}", actor)
        # rubocop:enable Gitlab/FeatureFlagKeyDynamic
      end

      def registry
        Registry.instance
      end
    end
  end
end
