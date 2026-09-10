---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Organizations
description: Namespace hierarchy.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409913) in GitLab 16.1 [with a feature flag](../../administration/feature_flags/_index.md) named `ui_for_organizations`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but still in development and not ready for production use.

Organizations will be above the [top-level namespaces](../namespace/_index.md) for you to manage
everything you do as a GitLab administrator, including:

- Defining and applying settings to all of your groups, subgroups, and projects.
- Aggregating data from all your groups, subgroups, and projects.

> [!disclaimer]

For more information about the state of organization development,
see [epic 9265](https://gitlab.com/groups/gitlab-org/-/epics/9265).

## Create an organization

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/441531) in GitLab 16.11 [with a feature flag](../../administration/feature_flags/_index.md) named `allow_organization_creation`. Disabled by default.
- Feature flag [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/549062) to `organization_switching` in GitLab 18.4. Disabled by default. Feature flag `allow_organization_creation` removed.
- Feature flag [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249678) to `org_stage_experimental` in GitLab 19.4. Disabled by default. Feature flag `organization_switching` removed.

{{< /history >}}

You create an organization from one of your existing top-level groups. During this process you can also move your other top-level groups into the organization.

Prerequisites:

- You must have the Owner role for the top-level group you start from, and for any other top-level groups you want to include.

Create an organization from an existing top-level group.
After you create your organization, all of your groups,
projects, and users are transferred from the top-level
group into your organization.

If you have the Owner role for multiple top-level groups,
you can optionally transfer those top-level groups into the
organization.

Prerequisites:

- The Owner role for any top-level groups you want to transfer to an organization.

To create an organization:

1. In the top bar, select **Search or go to** and find your group. This group must be at the top level.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Advanced**.
1. In the **Create an organization** section, select **Create organization**.
1. In the **Create your Organizations** confirmation dialog, select the group you want to create an organization with, then select **Continue**.
1. If you have the Owner role for multiple top-level groups (if you do not have multiple top-level groups, skip this step):
   - In the **Assign top-level groups** confirmation dialog, drag top-level groups into the organization container to assign them. Groups you do not assign are not included in the organization.
   - Select **Continue**.
1. In the **Confirm your organization** confirmation dialog, review the proposed organization structure. After you confirm your organization structure, you cannot delete the organization or remove or add top-level groups.
1. Select **Confirm**.

> [!note]
> After you confirm your organization structure, you cannot delete the organization or remove or
> add top-level groups yourself. [Contact support](https://support.gitlab.com/) if you must make changes.

After you confirm your organization structure:

- Your groups, projects, and users are transferred into the
organization asynchronously. You receive an email when the organization is ready. Larger groups might
take longer to transfer.
- Any users with the Owner role for top-level groups 
assigned to the organization automatically become Organization Administrators. You can make changes to roles and permissions in **Organization settings**.

When the organization is ready, you can:

- Access your organization in the UI or
from the link in the notification email.
- Rename the organization, change its URL,
and manage organization roles and permissions.

## Go to your organization

Prerequisites:

- An organization is available.

If you are a member of one or more organizations, you can go to any of them from the
**Organizations** page. To access an organization:

1. In the left sidebar, select **Organizations**.
1. From the list, select the organization you want to go to.

## Supported Markdown for Organization description

The Organization description field supports a limited subset of [GitLab Flavored Markdown](../markdown.md), including:

- [Emphasis](../markdown.md#emphasis)
- [Links](../markdown.md#links)
- [Superscripts / Subscripts](../markdown.md#superscripts-and-subscripts)
