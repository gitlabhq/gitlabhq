# frozen_string_literal: true

module Ci
  class BuildPolicy < CommitStatusPolicy
    include Ci::DeployablePolicy

    delegate(:project) { @subject.project }

    condition(:public_project, scope: :subject) do
      @subject.project.public?
    end

    condition(:guest) do
      can?(:guest_access, @subject.project)
    end

    condition(:protected_ref) do
      access = ::Gitlab::UserAccess.new(@user, container: @subject.project)

      if @subject.tag?
        !access.can_create_tag?(@subject.ref)
      else
        !access.can_update_branch?(@subject.ref)
      end
    end

    condition(:unprotected_ref, scope: :subject) do
      if @subject.tag?
        !ProtectedTag.protected?(@subject.project, @subject.ref)
      else
        !ProtectedBranch.protected?(@subject.project, @subject.ref)
      end
    end

    condition(:owner_of_job) do
      @subject.triggered_by?(@user)
    end

    condition(:branch_allows_collaboration) do
      @subject.project.branch_allows_collaboration?(@user, @subject.ref)
    end

    condition(:archived, scope: :subject) do
      @subject.archived?(log: true)
    end

    condition(:artifacts_public, scope: :subject) do
      @subject.artifacts_public?
    end

    condition(:artifacts_none, scope: :subject) do
      @subject.artifacts_no_access?
    end

    condition(:terminal, scope: :subject) do
      @subject.has_terminal?
    end

    condition(:is_web_ide_terminal, scope: :subject) do
      @subject.pipeline.webide?
    end

    condition(:debug_mode, scope: :subject, score: 32) do
      @subject.debug_mode?
    end

    condition(:can_read_project_build) do
      can?(:read_build, @subject.project)
    end

    condition(:project_update_build) do
      can?(:update_build, @subject.project)
    end

    condition(:project_developer) do
      can?(:developer_access, @subject.project)
    end

    condition(:explicit_member) { @subject.project.member?(@user) }

    rule { public_project & project_developer }.enable :read_manual_variables
    rule { ~public_project & explicit_member }.enable :read_manual_variables

    # Use admin_ci_minutes for detailed quota and usage reporting
    # this is limited to total usage and total quota for a builds namespace
    rule { can_read_project_build }.policy do
      enable :read_ci_minutes_limited_summary
      enable :read_build_trace
    end

    rule { debug_mode & ~project_update_build }.prevent :read_build_trace

    # Authorizing the user to access to protected entities.
    # There is a "jailbreak" mode to exceptionally bypass the authorization,
    # however, you should NEVER allow it, rather suspect it's a wrong feature/product design.
    rule { ~can?(:jailbreak) & (archived | protected_ref) }.policy do
      ProjectPolicy::UPDATE_JOB_PERMISSIONS.each { |perm| prevent(perm) }
      ProjectPolicy::CLEANUP_JOB_PERMISSIONS.each { |perm| prevent(perm) }
    end

    rule { can?(:admin_build) | (can?(:update_build) & owner_of_job & unprotected_ref) }.enable :erase_build

    rule { can?(:public_access) & branch_allows_collaboration }.policy do
      enable :cancel_build

      ProjectPolicy::UPDATE_JOB_PERMISSIONS.each { |perm| enable(perm) }
    end

    rule { can?(:update_build) & terminal & owner_of_job }.enable :create_build_terminal

    rule { is_web_ide_terminal & can?(:create_web_ide_terminal) & (admin | owner_of_job) }.policy do
      enable :read_web_ide_terminal
      enable :update_web_ide_terminal
    end

    rule { is_web_ide_terminal & ~can?(:update_web_ide_terminal) }.policy do
      prevent :create_build_terminal
    end

    rule { can?(:update_web_ide_terminal) & terminal }.policy do
      enable :create_build_terminal
      enable :create_build_service_proxy
    end

    rule { ~can?(:build_service_proxy_enabled) }.policy do
      prevent :create_build_service_proxy
    end

    rule { can_read_project_build & ~artifacts_none }.enable :read_job_artifacts
    rule { ~artifacts_public & ~project_developer }.prevent :read_job_artifacts
  end
end

Ci::BuildPolicy.prepend_mod_with('Ci::BuildPolicy')
