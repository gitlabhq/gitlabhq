# frozen_string_literal: true

module Ci
  class PipelinePolicy < BasePolicy
    delegate { @subject.project }

    condition(:protected_ref) { ref_protected?(@user, @subject.project, @subject.tag?, @subject.ref) }

    condition(:branch_allows_collaboration) do
      @subject.project.branch_allows_collaboration?(@user, @subject.ref)
    end

    condition(:external_pipeline, scope: :subject, score: 0) do
      @subject.external?
    end

    condition(:triggerer_of_pipeline) do
      @subject.triggered_by?(@user)
    end

    condition(:project_allows_read_dependency) do
      can?(:read_dependency, @subject.project)
    end

    condition(:project_allows_read_build) do
      can?(:read_build, @subject.project)
    end

    # Allow reading builds for external pipelines regardless of whether CI/CD is disabled
    overrides :read_build
    rule { project_allows_read_build | (external_pipeline & can?(:reporter_access)) }.policy do
      enable :read_build
    end

    # Disallow users without permissions from accessing internal pipelines
    rule { ~can?(:read_build) & ~external_pipeline }.policy do
      prevent :read_pipeline
    end

    rule { protected_ref }.policy do
      prevent :update_pipeline
      prevent :cancel_pipeline
    end

    rule { can?(:public_access) & branch_allows_collaboration }.policy do
      enable :update_pipeline
      enable :cancel_pipeline
    end

    rule { can?(:admin_pipeline) }.policy do
      enable :read_pipeline_variable
    end

    rule { can?(:update_pipeline) & triggerer_of_pipeline }.policy do
      enable :read_pipeline_variable
    end

    rule { project_allows_read_dependency }.policy do
      enable :read_dependency
    end

    def ref_protected?(user, project, tag, ref)
      access = ::Gitlab::UserAccess.new(user, container: project)

      if tag
        !access.can_create_tag?(ref)
      else
        !access.can_update_branch?(ref)
      end
    end
  end
end

Ci::PipelinePolicy.prepend_mod_with('Ci::PipelinePolicy')
