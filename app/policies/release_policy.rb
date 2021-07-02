# frozen_string_literal: true

class ReleasePolicy < BasePolicy
  delegate { @subject.project }

  condition(:protected_tag) do
    access = ::Gitlab::UserAccess.new(@user, container: @subject.project)

    !access.can_create_tag?(@subject.tag)
  end

  condition(:respect_protected_tag) do
    ::Feature.enabled?(:evalute_protected_tag_for_release_permissions, @subject.project, default_enabled: :yaml)
  end

  condition(:project_developer) do
    can?(:developer_access, @subject.project)
  end

  rule { respect_protected_tag & protected_tag }.policy do
    prevent :create_release
    prevent :update_release
    prevent :destroy_release
  end

  # NOTE: Developer role (or above) can create, update and destroy release entries.
  # When we remove the `evalute_protected_tag_for_release_permissions` feature flag,
  # we should move `enable :destroy_release` to ProjectPolicy alongside with .
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/327505 for more information.
  rule { respect_protected_tag & project_developer }.policy do
    enable :destroy_release
  end
end
