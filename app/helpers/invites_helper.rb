# frozen_string_literal: true

module InvitesHelper
  # Builds invitation URLs. For Cells organizations they are scoped under
  # `/o/<path>/` so the link routes to the cell that owns the organization.
  #
  # These use the explicit `organization_*` helpers rather than relying on
  # `Current.organization` auto-scoping: invite emails render in Sidekiq workers
  # (outside the request layer) and must target the member's source organization.
  # See doc/development/organization/_index.md ("Organization routing").
  #
  # rubocop:disable Gitlab/AvoidOrganizationUrlRoutes -- explicit helpers required, see above
  def invite_url_for(member, token, **options)
    organization = scoped_invite_organization(member)
    return invite_url(token, **options) unless organization

    organization_invite_url(token, organization_path: organization.path, **options)
  end

  def accept_invite_url_for(member, token, **options)
    organization = scoped_invite_organization(member)
    return accept_invite_url(token, **options) unless organization

    accept_organization_invite_url(token, organization_path: organization.path, **options)
  end

  def decline_invite_url_for(member, token, **options)
    organization = scoped_invite_organization(member)
    return decline_invite_url(token, **options) unless organization

    decline_organization_invite_url(token, organization_path: organization.path, **options)
  end
  # rubocop:enable Gitlab/AvoidOrganizationUrlRoutes

  private

  def scoped_invite_organization(member)
    organization = member.source&.organization
    return unless organization
    # Only non-default (Cells) organizations use `/o/<path>/` paths.
    return unless organization.scoped_paths?

    organization
  end
end
