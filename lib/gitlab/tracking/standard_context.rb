# frozen_string_literal: true

module Gitlab
  module Tracking
    class StandardContext
      GITLAB_STANDARD_SCHEMA_URL = 'iglu:com.gitlab/gitlab_standard/jsonschema/1-0-8'
      GITLAB_RAILS_SOURCE = 'gitlab-rails'

      def initialize(namespace: nil, project: nil, user: nil, **extra)
        check_argument_type(:namespace, namespace, [Namespace])
        check_argument_type(:project, project, [Project, Integer])
        check_argument_type(:user, user, [User, DeployToken])

        @namespace = namespace
        @plan = namespace&.actual_plan_name
        @project = project
        @user = user
        @extra = extra
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

      attr_accessor :namespace, :project, :extra, :plan, :user

      def to_h
        {
          environment: environment,
          source: source,
          plan: plan,
          extra: extra,
          user_id: user&.id,
          namespace_id: namespace&.id,
          project_id: project_id,
          context_generated_at: Time.current
        }
      end

      def project_id
        project.is_a?(Integer) ? project : project&.id
      end

      def check_argument_type(argument_name, argument_value, allowed_classes)
        return if argument_value.nil? || allowed_classes.any? { |allowed_class| argument_value.is_a?(allowed_class) }

        exception = "Invalid argument type passed for #{argument_name}." \
          " Should be one of #{allowed_classes.map(&:to_s)}"
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new(exception))
      end
    end
  end
end
