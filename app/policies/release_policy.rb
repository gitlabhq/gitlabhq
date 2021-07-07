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

  rule { respect_protected_tag & protected_tag }.policy do
    prevent :create_release
    prevent :update_release
    prevent :destroy_release
  end
end
