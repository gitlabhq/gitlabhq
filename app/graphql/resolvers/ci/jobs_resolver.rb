# frozen_string_literal: true

module Resolvers
  module Ci
    class JobsResolver < BaseResolver
      include LooksAhead

      alias_method :pipeline, :object

      type ::Types::Ci::JobType.connection_type, null: true

      # A bridge's detailed status resolves :play_job and :read_pipeline on the
      # downstream pipeline, so it needs the downstream project.
      POLICY_FIELD_PRELOADS = {
        detailed_status: %i[deployments downstream_projects],
        playable: %i[deployments],
        can_play_job: %i[deployments downstream_projects]
      }.freeze

      before_connection_authorization do |jobs, current_user, context|
        groups = context[:ci_job_policy_preloads].to_h[jobs.first&.project_id]

        if groups.present?
          ::Ci::Preloaders::JobPolicyPreloader.new(
            jobs, current_user,
            deployments: groups.include?(:deployments),
            downstream_projects: groups.include?(:downstream_projects)
          ).execute
        end
      end

      argument :job_kind, ::Types::Ci::JobKindEnum,
        required: false,
        description: 'Filter jobs by kind.'

      argument :retried, ::GraphQL::Types::Boolean,
        required: false,
        description: 'Filter jobs by retry-status.'

      argument :security_report_types, [Types::Security::ReportTypeEnum],
        required: false,
        description: 'Filter jobs by the type of security report they produce.'

      argument :statuses, [::Types::Ci::JobStatusEnum],
        required: false,
        description: 'Filter jobs by status.'

      argument :when_executed, [::GraphQL::Types::String],
        required: false,
        description: 'Filter jobs by when they are executed.'

      def resolve_with_lookahead(
        job_kind: nil,
        retried: nil,
        security_report_types: [],
        statuses: nil,
        when_executed: nil)
        record_policy_preloads

        jobs = init_collection(security_report_types)
        jobs = jobs.latest if retried == false
        jobs = jobs.retried if retried
        jobs = jobs.with_status(statuses) if statuses.present?
        jobs = jobs.with_type(job_kind) if job_kind
        jobs = jobs.with_when_executed(when_executed) if when_executed.present?

        return jobs unless preload_page_associations?

        apply_lookahead(jobs.extending(::Ci::Preloaders::CommitStatusRelationExtension))
      end

      def init_collection(security_report_types)
        if security_report_types.present?
          ::Security::SecurityJobsFinder.new(
            pipeline: pipeline,
            job_types: security_report_types
          ).execute
        else
          pipeline.statuses_order_id_desc
        end
      end

      private

      # Keyed by project because the flag has a project actor, so a query spanning
      # two projects doesn't preload for the one the flag is off for.
      def record_policy_preloads
        return if ::Feature.disabled?(:batch_pipeline_job_policy_checks, ::Project.actor_from_id(pipeline.project_id))

        groups = policy_preload_groups
        return if groups.empty?

        recorded = context[:ci_job_policy_preloads] ||= {}
        recorded[pipeline.project_id] = recorded[pipeline.project_id].to_a | groups
      end

      def policy_preload_groups
        selections = node_selection.selections
        groups = selections.flat_map { |selection| POLICY_FIELD_PRELOADS.fetch(selection.name, []) }

        groups | write_permission_groups(selections)
      end

      # Permission subfields are named after their abilities. Only write abilities
      # read deployments, and JobPermissions doesn't expose :play_job.
      def write_permission_groups(selections)
        permissions = selections.find { |selection| selection.name == :user_permissions }
        return [] unless permissions

        return [] unless permissions.selections.map(&:name).intersect?(::Ci::BuildPolicy.all_job_write_abilities)

        %i[deployments]
      end

      def preload_page_associations?
        Feature.enabled?(:batch_preload_pipeline_job_associations, pipeline.project)
      end

      def preloads
        {
          artifacts: [{ job_artifacts: :project }],
          browse_artifacts_path: [:project],
          commit_path: [:project],
          detailed_status: [
            :error_job_messages, :project, { downstream_pipeline: { project: { namespace: :route } } }
          ],
          playable: [:job_definition],
          play_path: [:project],
          ref_path: [:project],
          retryable: [:job_definition],
          retry_path: [:project, :job_definition],
          stuck: [:project],
          tags: [:job_definition],
          web_path: [:project],
          [:user_permissions, :read_job_artifacts] => [:job_artifacts_archive]
        }
      end
    end
  end
end
