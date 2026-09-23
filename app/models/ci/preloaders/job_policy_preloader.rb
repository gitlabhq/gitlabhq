# frozen_string_literal: true

module Ci
  module Preloaders
    # Loads what Ci::BuildPolicy and Ci::DeployablePolicy read per job, so a page
    # of mixed builds, bridges and generic statuses can be policy-checked without
    # per-job queries.
    class JobPolicyPreloader
      def initialize(jobs, user)
        @jobs = jobs
        @user = user
      end

      def execute
        preload_associations
        assign_persisted_environments
        preload_last_deployments
        preload_protected_environments
        preload_downstream_projects

        environments
      end

      private

      attr_reader :jobs, :user

      def processables
        @processables ||= jobs.select { |job| job.is_a?(::Ci::Processable) }
      end

      def bridges
        @bridges ||= jobs.select { |job| job.is_a?(::Ci::Bridge) }
      end

      def deployments
        @deployments ||= processables.filter_map(&:deployment)
      end

      # One preloader across builds and bridges, so a row referenced from several
      # jobs or associations is one instance.
      def preload_associations
        return if jobs.empty?

        ActiveRecord::Associations::Preloader.new(
          records: jobs, associations: :project, available_records: loaded_pipeline_projects
        ).call

        return if processables.empty?

        # Rails batches both :environment branches into one query, so a job's
        # job_environment.environment and deployment.environment are one instance.
        ActiveRecord::Associations::Preloader.new(
          records: processables,
          associations: [:job_definition, { job_environment: :environment }, { deployment: :environment }]
        ).call

        return if bridges.empty?

        ActiveRecord::Associations::Preloader.new(
          records: bridges, associations: [:ci_stage, { downstream_pipeline: :project }]
        ).call
      end

      # Jobs loaded through the pipeline's association already hold the pipeline and
      # its project, so Rails reuses that instance instead of querying.
      def loaded_pipeline_projects
        jobs.filter_map { |job| job.association(:pipeline).target&.association(:project)&.target }.uniq(&:object_id)
      end

      # Without this, every environment job resolves persisted_environment by name.
      def assign_persisted_environments
        processables.each do |job|
          environment = job.job_environment&.environment || job.deployment&.environment
          next unless environment

          job.clear_memoization(:persisted_environment)
          job.persisted_environment = environment
          # EE::Environment#protected? memoizes licence checks per Project instance.
          environment.association(:project).target = job.project unless environment.association(:project).loaded?
        end
      end

      def preload_last_deployments
        return if environments.empty?

        ::Preloaders::Environments::DeploymentPreloader.new(environments).execute_with_union(:last_deployment, [])
      end

      # Overridden in EE. Runs before preload_downstream_projects because
      # EE Bridge#playable? reads deployment approvals.
      def preload_protected_environments; end

      # Bridge statuses check :read_pipeline on the downstream pipeline, and manual
      # bridges that have not run resolve their downstream project by path.
      def preload_downstream_projects
        return if bridges.empty?

        # Only play_job reads Bridge#downstream_project, and only for playable bridges.
        # Paths with variable references need the bridge's variables (and Gitaly) to
        # expand, so those keep the per-bridge lookup.
        paths_by_bridge = bridges.select(&:playable?).index_with { |bridge| literal_trigger_path(bridge) }.compact
        projects_by_path = ::Project.where_full_path_in(paths_by_bridge.values.uniq)
          .index_by { |project| project.full_path.downcase }

        paths_by_bridge.each do |bridge, path|
          bridge.downstream_project = projects_by_path[path.downcase]
        end

        projects = bridges.filter_map { |bridge| bridge.downstream_pipeline&.project }
        projects += projects_by_path.values
        projects.uniq!(&:object_id)
        return if projects.empty?

        ::Preloaders::ProjectPolicyPreloader.new(projects, user).execute
        ActiveRecord::Associations::Preloader.new(
          records: projects, associations: [:project_feature, { namespace: :namespace_settings }]
        ).call
      end

      def literal_trigger_path(bridge)
        path = bridge.options.dig(:trigger, :project)
        path unless ExpandVariables.possible_var_reference?(path)
      end

      def environments
        @environments ||= processables
          .flat_map { |job| [job.job_environment&.environment, job.deployment&.environment] }
          .compact.uniq(&:object_id)
      end
    end
  end
end

Ci::Preloaders::JobPolicyPreloader.prepend_mod
