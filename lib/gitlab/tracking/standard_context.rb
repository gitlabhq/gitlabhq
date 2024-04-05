# frozen_string_literal: true

module Gitlab
  module Tracking
    class StandardContext
      GITLAB_STANDARD_SCHEMA_URL = 'iglu:com.gitlab/gitlab_standard/jsonschema/1-0-10'
      GITLAB_RAILS_SOURCE = 'gitlab-rails'

      def initialize(
        namespace_id: nil, plan_name: nil, project_id: nil, user_id: nil,
        feature_enabled_by_namespace_ids: nil, **extra)
        check_argument_type(:namespace_id, namespace_id, [Integer])
        check_argument_type(:plan_name, plan_name, [String])
        check_argument_type(:project_id, project_id, [Integer])
        check_argument_type(:user_id, user_id, [Integer])

        @namespace_id = namespace_id
        @plan_name = plan_name
        @project_id = project_id
        @user_id = user_id
        @extra = extra
        @feature_enabled_by_namespace_ids = feature_enabled_by_namespace_ids
      end

      def to_context
        SnowplowTracker::SelfDescribingJson.new(GITLAB_STANDARD_SCHEMA_URL, to_h)
      end

      def environment
        return 'staging' if Gitlab.staging?

        return 'production' if Gitlab.com?

        return 'org' if Gitlab.org?

        return 'self-managed' if Rails.env.production?

        'development'
      end

      def source
        GITLAB_RAILS_SOURCE
      end

      private

      attr_accessor :namespace_id, :project_id, :extra, :plan_name, :user_id, :feature_enabled_by_namespace_ids

      def to_h
        {
          environment: environment,
          source: source,
          plan: plan_name,
          extra: extra,
          user_id: user_id,
          is_gitlab_team_member: gitlab_team_member?(user_id),
          namespace_id: namespace_id,
          project_id: project_id,
          feature_enabled_by_namespace_ids: feature_enabled_by_namespace_ids,
          context_generated_at: Time.current
        }
      end

      def check_argument_type(argument_name, argument_value, allowed_classes)
        return if argument_value.nil? || allowed_classes.any? { |allowed_class| argument_value.is_a?(allowed_class) }

        exception = "Invalid argument type passed for #{argument_name}." \
          " Should be one of #{allowed_classes.map(&:to_s)}"
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new(exception))
      end

      # Overridden in EE
      def gitlab_team_member?(_user_id)
        nil
      end
    end
  end
end

Gitlab::Tracking::StandardContext.prepend_mod
