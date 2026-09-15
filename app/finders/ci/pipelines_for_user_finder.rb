# frozen_string_literal: true

module Ci
  # Lists pipelines triggered by the given user across all projects.
  #
  # Results are limited to recent Ci::Partition partitions so that queries
  # prune to a small number of partitions instead of scanning all of them.
  #
  # Callers must enforce per-project visibility on the (paginated) result
  # with .visible_to, because p_ci_pipelines lives on the CI database and
  # cannot be joined with main-database tables such as
  # project_authorizations.
  class PipelinesForUserFinder
    include CreatedAtFilter

    # Enforces per-project visibility on a materialized page of pipelines,
    # preloading the policy data needed for the per-pipeline checks.
    def self.visible_to(pipelines, user)
      projects = pipelines.map(&:project).uniq
      ::Preloaders::ProjectPolicyPreloader.new(projects, user).execute if projects.any?

      Ability.pipelines_readable_by_user(pipelines, user)
    end

    def initialize(user, params = {})
      @user = user
      @params = params
    end

    def execute
      items = prefiltered_pipelines
      items = by_source(items)
      items = by_created_at(items)

      items.order_created_at_desc_id_desc_keyset
    end

    private

    attr_reader :user, :params

    def prefiltered_pipelines
      pipelines = Ci::Pipeline.for_user(user).in_partition(Ci::Partition.recent_ids)
      return pipelines if params[:source] == 'parent_pipeline'

      pipelines.no_child
    end

    def by_source(items)
      return items unless ::Ci::Pipeline.sources.key?(params[:source])

      items.with_pipeline_source(params[:source])
    end
  end
end
