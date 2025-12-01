---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Organizations
description: Namespace hierarchy.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409913) in GitLab 16.1 [with a flag](../../administration/feature_flags/_index.md) named `ui_for_organizations`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

{{< alert type="disclaimer" />}}

{{< alert type="note" >}}

Organizations is in development.

{{< /alert >}}

Organizations will be above the [top-level namespaces](../namespace/_index.md) for you to manage
everything you do as a GitLab administrator, including:

- Defining and applying settings to all of your groups, subgroups, and projects.
- Aggregating data from all your groups, subgroups, and projects.

For more information about the state of organization development,
see [epic 9265](https://gitlab.com/groups/gitlab-org/-/epics/9265).

## Create an organization

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/441531) in GitLab 16.11 [with a flag](../../administration/feature_flags/_index.md) named `allow_organization_creation`. Disabled by default.
- [Consolidated](https://gitlab.com/gitlab-org/gitlab/-/issues/549062) with `organization_switching` feature flag in GitLab 18.4. Disabled by default.

{{< /history >}}

1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New organization**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. In the **Organization name** text box, enter a name for the organization.
1. In the **Organization URL** text box, enter a path for the organization.
1. In the **Organization description** text box, enter a description for the organization. Supports a [limited subset of Markdown](#supported-markdown-for-organization-description).
1. In the **Organization avatar** field, select **Upload** or drag and drop an avatar.
1. Select **Create organization**.

## Switch organizations

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440741) in GitLab 16.11 [with a flag](../../administration/feature_flags/_index.md) named `organization_switching`. Disabled by default.

{{< /history >}}

If you are a member of multiple organizations, you can switch between them. To switch organizations:

1. On the left sidebar, at the top, select the **Current organization** dropdown list.
1. Select the organization you want to switch to.

## Supported Markdown for Organization description

The Organization description field supports a limited subset of [GitLab Flavored Markdown](../markdown.md), including:

- [Emphasis](../markdown.md#emphasis)
- [Links](../markdown.md#links)
- [Superscripts / Subscripts](../markdown.md#superscripts-and-subscripts)
