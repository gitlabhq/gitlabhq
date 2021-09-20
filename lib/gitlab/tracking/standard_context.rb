# frozen_string_literal: true

module Gitlab
  module Tracking
    class StandardContext
      GITLAB_STANDARD_SCHEMA_URL = 'iglu:com.gitlab/gitlab_standard/jsonschema/1-0-5'
      GITLAB_RAILS_SOURCE = 'gitlab-rails'

      def initialize(namespace: nil, project: nil, user: nil, **extra)
        @namespace = namespace
        @plan = namespace&.actual_plan_name
        @project = project
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

      attr_accessor :namespace, :project, :extra, :plan

      def to_h
        {
          environment: environment,
          source: source,
          plan: plan,
          extra: extra
        }.merge(project_and_namespace)
      end

      def project_and_namespace
        return {} unless ::Feature.enabled?(:add_namespace_and_project_to_snowplow_tracking, default_enabled: :yaml)

        {
          namespace_id: namespace&.id,
          project_id: project_id
        }
      end

      def project_id
        project.is_a?(Integer) ? project : project&.id
      end
    end
  end
end
