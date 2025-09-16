# frozen_string_literal: true

module Ci
  class JobArtifactPolicy < BasePolicy
    delegate { @subject.job.project }

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

    condition(:has_access_to_project) do
      can?(:developer_access, @subject.job.project)
    end

    condition(:has_maintainer_access_to_project) do
      can?(:maintainer_access, @subject.job.project)
    end

    rule { can_read_project_build & ~none_access }.enable :read_job_artifacts
    rule { ~public_access & ~has_access_to_project }.prevent :read_job_artifacts
    rule { maintainer_only_access & ~has_maintainer_access_to_project }.prevent :read_job_artifacts
  end
end
