# frozen_string_literal: true

module Ci
  class JobArtifactPolicy < BasePolicy
    delegate { @subject.job.project }

    # Ensure read_job_artifacts does not get prevented due to prevent_all in the delegate
    # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229560
    overrides(:read_job_artifacts)

    condition(:public_access, scope: :subject) do
      @subject.public_access? # public:true | access:all
    end

    condition(:none_access, scope: :subject) do
      @subject.none_access? # access:none
    end

    condition(:maintainer_only_access, scope: :subject) do
      @subject.maintainer_access?
    end

    condition(:can_read_project_build) do
      can?(:read_build, @subject.job.project)
    end

    condition(:can_read_developer_artifacts) do
      can?(:_read_developer_job_artifact, @subject.job.project)
    end

    condition(:can_read_maintainer_artifacts) do
      can?(:_read_maintainer_job_artifact, @subject.job.project)
    end

    rule { can_read_project_build & ~none_access }.enable :read_job_artifacts
    rule { ~public_access & ~can_read_developer_artifacts }.prevent :read_job_artifacts
    rule { maintainer_only_access & ~can_read_maintainer_artifacts }.prevent :read_job_artifacts
  end
end
