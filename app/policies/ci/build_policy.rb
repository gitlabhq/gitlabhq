# frozen_string_literal: true

module Ci
  class BuildPolicy < CommitStatusPolicy
    condition(:protected_ref) do
      access = ::Gitlab::UserAccess.new(@user, container: @subject.project)

      if @subject.tag?
        !access.can_create_tag?(@subject.ref)
      else
        !access.can_update_branch?(@subject.ref)
      end
    end

    condition(:unprotected_ref) do
      if @subject.tag?
        !ProtectedTag.protected?(@subject.project, @subject.ref)
      else
        !ProtectedBranch.protected?(@subject.project, @subject.ref)
      end
    end

    # overridden in EE
    condition(:protected_environment_access) do
      false
    end

    condition(:owner_of_job) do
      @subject.triggered_by?(@user)
    end

    condition(:branch_allows_collaboration) do
      @subject.project.branch_allows_collaboration?(@user, @subject.ref)
    end

    condition(:archived, scope: :subject) do
      @subject.archived?
    end

    condition(:terminal, scope: :subject) do
      @subject.has_terminal?
    end

    condition(:is_web_ide_terminal, scope: :subject) do
      @subject.pipeline.webide?
    end

    rule { ~protected_environment_access & (protected_ref | archived) }.policy do
      prevent :update_build
      prevent :update_commit_status
      prevent :erase_build
    end

    rule { can?(:admin_build) | (can?(:update_build) & owner_of_job & unprotected_ref) }.enable :erase_build

    rule { can?(:public_access) & branch_allows_collaboration }.policy do
      enable :update_build
      enable :update_commit_status
    end

    rule { can?(:update_build) & terminal }.enable :create_build_terminal

    rule { can?(:update_build) }.enable :play_job

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
  end
end

Ci::BuildPolicy.prepend_if_ee('EE::Ci::BuildPolicy')
