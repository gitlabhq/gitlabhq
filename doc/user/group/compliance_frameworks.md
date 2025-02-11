---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance frameworks
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can create a compliance framework that is a label to identify that your project has certain compliance
requirements or needs additional oversight.

In the Ultimate tier, the compliance framework can optionally enforce
[compliance pipeline configuration](compliance_pipelines.md) and
[security policies](../application_security/policies/_index.md#scope) to the projects on which it is applied.

Compliance frameworks are created on top-level groups. If a project is moved outside of its existing top-level group,
its frameworks are removed.

You can apply up to 20 compliance frameworks to each project.

For a click-through demo, see [Compliance frameworks](https://gitlab.navattic.com/compliance).
<!-- Demo published on 2025-01-27 -->

## Prerequisites

- To create, edit, and delete compliance frameworks, users must have either:
  - The Owner role for the top-level group.
  - Be assigned a [custom role](../custom_roles.md) with the `admin_compliance_framework`
    [custom permission](../custom_roles/abilities.md#compliance-management).
- To add or remove a compliance framework to or from a project, the group to which the project belongs must have a
  compliance framework.

## Create, edit, or delete a compliance framework

You can create, edit, or delete a compliance framework from a compliance framework report. For more information, see:

- [Create a new compliance framework](../compliance/compliance_center/compliance_frameworks_report.md#create-a-new-compliance-framework).
- [Edit a compliance framework](../compliance/compliance_center/compliance_frameworks_report.md#edit-a-compliance-framework).
- [Delete a compliance framework](../compliance/compliance_center/compliance_frameworks_report.md#delete-a-compliance-framework).

You can create, edit, or delete a compliance framework from a compliance projects report. For more information, see:

- [Create a new compliance framework](../compliance/compliance_center/compliance_projects_report.md#create-a-new-compliance-framework).
- [Edit a compliance framework](../compliance/compliance_center/compliance_projects_report.md#edit-a-compliance-framework).
- [Delete a compliance framework](../compliance/compliance_center/compliance_projects_report.md#delete-a-compliance-framework).

Subgroups and projects have access to all compliance frameworks created on their top-level group. However, compliance frameworks cannot be created, edited,
or deleted at the subgroup or project level. Project owners can choose a framework to apply to their projects.

## Apply a compliance framework to a project

> - Assigning multiple compliance frameworks [introduced](https://gitlab.com/groups/gitlab-org/-/epics/13294) in GitLab 17.3.

You can apply multiple compliance frameworks to a project but cannot apply compliance frameworks to projects in personal namespaces.

To apply a compliance framework to a project, apply the compliance framework through the
[Compliance projects report](../compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group).

You can use the [GraphQL API](../../api/graphql/reference/_index.md#mutationprojectsetcomplianceframework) to apply a
compliance framework to a project.

If you create compliance frameworks on subgroups with GraphQL, the framework is created on the root ancestor if the user
has the correct permissions. The GitLab UI presents a read-only view to discourage this behavior.

## Default compliance frameworks

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375036) in GitLab 15.6.

Group owners can set a default compliance framework. The default framework is applied to all the new and imported
projects that are created in that group. It does not affect the framework applied to the existing projects. The
default framework cannot be deleted.

A compliance framework that is set to default has a **default** label.

### Set and remove a default by using the compliance center

To set as default (or remove the default) from [compliance projects report](../compliance/compliance_center/compliance_projects_report.md):

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Hover over a compliance framework, select the **Edit Framework** tab.
1. Select **Set as default**.
1. Select **Save changes**.

To set as default (or remove the default) from [compliance framework report](../compliance/compliance_center/compliance_frameworks_report.md):

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.
1. Hover over a compliance framework, select the **Edit Framework** tab.
1. Select **Set as default**.
1. Select **Save changes**.

## Remove a compliance framework from a project

To remove a compliance framework from one or multiple project in a group, remove the compliance framework through the
[Compliance projects report](../compliance/compliance_center/compliance_projects_report.md#remove-a-compliance-framework-from-projects-in-a-group).
