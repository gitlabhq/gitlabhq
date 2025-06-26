# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      class AccessLogger
        include ::Gitlab::Utils::StrongMemoize

        PROVISIONAL_ARCHIVE_VALUE = 90.days

        def initialize(pipeline:, archived:, destination: Gitlab::AppJsonLogger)
          @pipeline = pipeline
          @archived = archived
          @destination = destination
        end

        def log
          return unless enabled?

          log_access_entry if log_access?
        end

        private

        attr_reader :pipeline, :destination

        delegate :project, to: :pipeline

        def archived?
          @archived
        end

        # Tracks interactions with pipelines that are archived or will be archived (90+ days old).
        # Helps assess impact of archival policies on user workflows before implementation.
        # Primarily for GitLab.com data collection.
        #
        def enabled?
          ::Gitlab::SafeRequestStore.fetch(:ci_pipeline_archived_access) do
            ::Feature.enabled?(:ci_pipeline_archived_access, :current_request, type: :ops)
          end
        end
        strong_memoize_attr :enabled?

        def log_access_entry
          ::Gitlab::ApplicationContext.with_context(project: project) do
            attributes = ::Gitlab::ApplicationContext.current.merge(
              class: self.class.name.to_s,
              graphql: graphql_operation_names,
              project_id: project.id,
              pipeline_id: pipeline.id,
              pipeline_age: pipeline.age_in_minutes,
              archived: archived?
            )

            attributes.deep_stringify_keys!
            destination.info(attributes)
          end
        end

        def graphql_operation_names
          RequestStore.store[:graphql_logs].to_a.map { |log| log.slice(:operation_name) }
        end

        def log_access?
          archived? || pipeline_will_be_archived?
        end

        def pipeline_will_be_archived?
          pipeline.created_at.before?(PROVISIONAL_ARCHIVE_VALUE.ago)
        end
      end
    end
  end
end
