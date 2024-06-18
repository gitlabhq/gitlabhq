# frozen_string_literal: true

module Gitlab
  module Access
    class DefaultBranchProtection
      attr_reader :settings

      def initialize(settings)
        @settings = settings.deep_symbolize_keys
      end

      def code_owner_approval_required?
        !!settings[:code_owner_approval_required]
      end

      def allow_force_push?
        !!settings[:allow_force_push]
      end

      def any?
        return true unless settings[:allow_force_push]

        allowed_to_merge_values = settings[:allowed_to_merge]
        allowed_to_push_values = settings[:allowed_to_push]

        any_push_levels_not_developer = allowed_to_push_values.any? do |entry|
          entry[:access_level] != Gitlab::Access::DEVELOPER
        end

        any_merge_levels_not_developer = allowed_to_merge_values.any? do |entry|
          entry[:access_level] != Gitlab::Access::DEVELOPER
        end

        any_push_levels_not_developer || any_merge_levels_not_developer
      end

      def no_one_can_push?
        allowed_to_push_values = settings[:allowed_to_push]
        allowed_to_push_values.any? { |entry| entry[:access_level] == Gitlab::Access::NO_ACCESS }
      end

      def no_one_can_merge?
        allowed_to_merge_values = settings[:allowed_to_merge]
        allowed_to_merge_values.any? { |entry| entry[:access_level] == Gitlab::Access::NO_ACCESS }
      end

      def maintainer_can_push?
        allowed_to_push_values = settings[:allowed_to_push]
        allowed_to_push_values.any? { |entry| entry[:access_level] == Gitlab::Access::MAINTAINER }
      end

      def maintainer_can_merge?
        allowed_to_merge_values = settings[:allowed_to_merge]
        allowed_to_merge_values.any? { |entry| entry[:access_level] == Gitlab::Access::MAINTAINER }
      end

      def developer_can_push?
        allowed_to_push_values = settings[:allowed_to_push]
        allowed_to_push_values.any? { |entry| entry[:access_level] == Gitlab::Access::DEVELOPER }
      end

      def developer_can_initial_push?
        settings[:developer_can_initial_push].present?
      end

      def developer_can_merge?
        allowed_to_merge_values = settings[:allowed_to_merge]
        allowed_to_merge_values.any? { |entry| entry[:access_level] == Gitlab::Access::DEVELOPER }
      end

      def fully_protected?
        return false if settings[:allow_force_push] || developer_can_initial_push?

        allowed_to_merge_values = settings[:allowed_to_merge]
        allowed_to_push_values = settings[:allowed_to_push]

        all_push_levels_at_maintainer = allowed_to_push_values.all? do |entry|
          entry[:access_level] == Gitlab::Access::MAINTAINER
        end

        all_merge_levels_at_maintainer = allowed_to_merge_values.all? do |entry|
          entry[:access_level] == Gitlab::Access::MAINTAINER
        end

        all_push_levels_at_maintainer && all_merge_levels_at_maintainer
      end
    end
  end
end
