# frozen_string_literal: true

module Gitlab
  module Tracking
    class StandardContext
      GITLAB_STANDARD_SCHEMA_URL = 'iglu:com.gitlab/gitlab_standard/jsonschema/1-1-7'
      GITLAB_RAILS_SOURCE = 'gitlab-rails'
      GITLAB_REALM_SELF_MANAGED = 'self-managed'

      def initialize(
        namespace: nil, project_id: nil, user: nil,
        feature_enabled_by_namespace_ids: nil, **extra)
        check_argument_type(:namespace, namespace, Namespace)
        check_argument_type(:project_id, project_id, Integer)
        check_argument_type(:user, user, User)

        plan_name = get_plan_name(namespace)
        check_argument_type(:plan_name, plan_name, String)

        @namespace = namespace
        @plan_name = plan_name
        @project_id = project_id
        @user = user
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

      attr_accessor :namespace, :project_id, :extra, :plan_name, :user, :feature_enabled_by_namespace_ids

      def get_plan_name(_namespace)
        'free' # GitLab CE edition is always free
      end

      def to_h
        {
          environment: environment,
          source: source,
          correlation_id: Labkit::Correlation::CorrelationId.current_or_new_id,
          plan: plan_name,
          extra: extra,
          user_id: tracked_user_id,
          global_user_id: global_user_id,
          user_type: tracked_user_type,
          is_gitlab_team_member: gitlab_team_member?(user&.id),
          namespace_id: namespace&.id,
          ultimate_parent_namespace_id: namespace&.root_ancestor&.id,
          project_id: project_id,
          feature_enabled_by_namespace_ids: feature_enabled_by_namespace_ids,
          realm: realm,
          deployment_type: deployment_type,
          instance_id: ::Gitlab::GlobalAnonymousId.instance_id,
          unique_instance_id: Gitlab::GlobalAnonymousId.instance_uuid,
          host_name: Gitlab.config.gitlab.host,
          instance_version: Gitlab.version_info.to_s,
          context_generated_at: Time.current
        }
      end

      def tracked_user_id
        return unless user.is_a? User

        Gitlab::CryptoHelper.sha256(user.id)
      end

      def tracked_user_type
        return unless user.is_a? User

        user.user_type
      end

      def check_argument_type(argument_name, argument_value, allowed_class)
        return if argument_value.nil? || argument_value.is_a?(allowed_class)

        exception = "Invalid argument type passed for #{argument_name}. " \
          "Should be #{allowed_class}"
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new(exception))
      end

      def global_user_id
        return unless user.is_a? User

        Gitlab::GlobalAnonymousId.user_id(user)
      end

      # Overridden in EE
      def gitlab_team_member?(_user_id)
        nil
      end

      def realm
        GITLAB_REALM_SELF_MANAGED
      end

      def deployment_type
        GITLAB_REALM_SELF_MANAGED
      end
    end
  end
end

Gitlab::Tracking::StandardContext.prepend_mod
