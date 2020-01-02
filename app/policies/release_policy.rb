# frozen_string_literal: true

class ReleasePolicy < BasePolicy
  delegate { @subject.project }

  rule { allowed_to_read_evidence & external_authorization_service_disabled }.policy do
    enable :read_release_evidence
  end

  ##
  # evidence.summary includes the following entities:
  # - Release
  # - git-tag (Repository)
  # - Project
  # - Milestones
  # - Issues
  condition(:allowed_to_read_evidence) do
    can?(:read_release) &&
      can?(:download_code) &&
      can?(:read_project) &&
      can?(:read_milestone) &&
      can?(:read_issue)
  end

  ##
  # Currently, we don't support release evidence for the GitLab instances
  # that enables external authorization services.
  # See https://gitlab.com/gitlab-org/gitlab/issues/121930.
  condition(:external_authorization_service_disabled) do
    !Gitlab::ExternalAuthorization::Config.enabled?
  end
end
