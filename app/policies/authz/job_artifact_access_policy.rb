# frozen_string_literal: true

module Authz
  class JobArtifactAccessPolicy < ::BasePolicy
    delegate { @subject.project }

    # Ensure read_job_artifacts does not get prevented due to prevent_all in the delegate
    # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229560
    overrides(:read_job_artifacts)

    condition(:public_access, scope: :subject) do
      @subject.accessibility == 'public'
    end

    condition(:none_access, scope: :subject) do
      @subject.accessibility == 'none'
    end

    condition(:maintainer_only_access, scope: :subject) do
      @subject.accessibility == 'maintainer'
    end

    condition(:can_read_project_build) do
      can?(:read_build, @subject.project)
    end

    condition(:can_read_developer_artifacts) do
      can?(:_read_developer_job_artifact, @subject.project)
    end

    condition(:can_read_maintainer_artifacts) do
      can?(:_read_maintainer_job_artifact, @subject.project)
    end

    condition(:can_read_security_report_job_artifacts) do
      ::Enums::Ci::JobArtifact.all_security_report_file_types.include?(@subject.file_type) &&
        can?(:_read_security_report_job_artifact, @subject.project)
    end

    rule { can_read_project_build & ~none_access }.enable :read_job_artifacts
    rule { ~public_access & ~can_read_developer_artifacts & ~can_read_security_report_job_artifacts }
      .prevent :read_job_artifacts
    rule { maintainer_only_access & ~can_read_maintainer_artifacts }.prevent :read_job_artifacts
  end
end
