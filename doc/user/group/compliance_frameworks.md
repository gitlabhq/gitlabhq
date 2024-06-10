---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Compliance frameworks

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can create a compliance framework that is a label to identify that your project has certain compliance
requirements or needs additional oversight. The label can optionally enforce
[compliance pipeline configuration](compliance_pipelines.md) to the projects on which it is applied.

Compliance frameworks are created on top-level groups. Users must have the Owner or Maintainer role in the top-level group or be assigned a [custom role](../../user/custom_roles) with the `admin_compliance_framework` [custom permission](../../user/custom_roles/abilities.md#compliance-management) to create, edit, and delete compliance frameworks.

NOTE:
If a project is moved outside of its existing top-level group, its framework is removed.

## Create, edit, or delete a compliance framework

### From compliance frameworks report

You can create, edit, or delete a compliance framework from a compliance framework report. For more information, see:

- [Create a new compliance framework](../../user/compliance/compliance_center/compliance_frameworks_report.md#create-a-new-compliance-framework).
- [Edit a compliance framework](../../user/compliance/compliance_center/compliance_frameworks_report.md#edit-a-compliance-framework).
- [Delete a compliance framework](../../user/compliance/compliance_center/compliance_frameworks_report.md#delete-a-compliance-framework).

### From compliance projects report

You can create, edit, or delete a compliance framework from a compliance projects report. For more information, see:

- [Create a new compliance framework](../../user/compliance/compliance_center/compliance_projects_report.md#create-a-new-compliance-framework).
- [Edit a compliance framework](../../user/compliance/compliance_center/compliance_projects_report.md#edit-a-compliance-framework).
- [Delete a compliance framework](../../user/compliance/compliance_center/compliance_projects_report.md#delete-a-compliance-framework).

Subgroups and projects have access to all compliance frameworks created on their top-level group. However, compliance frameworks cannot be created, edited,
or deleted at the subgroup or project level. Project owners can choose a framework to apply to their projects.

## Add a compliance framework to a project

Prerequisites:

- The group to which the project belongs must have a compliance framework.

NOTE:
Frameworks cannot be added to projects in personal namespaces.

### From compliance projects report

To assign a compliance framework to a project, apply the compliance framework through the
[Compliance projects report](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group).

### GraphQL API

You can use the [GraphQL API](../../api/graphql/reference/index.md#mutationprojectsetcomplianceframework) to add a
compliance framework to a project.

If you create compliance frameworks on subgroups with GraphQL, the framework is created on the root ancestor if the user
has the correct permissions. The GitLab UI presents a read-only view to discourage this behavior.

## Default compliance frameworks

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375036) in GitLab 15.6.

Group owners can set a default compliance framework. The default framework is applied to all the new and imported
projects that are created in that group. It does not affect the framework applied to the existing projects. The
default framework cannot be deleted.

A compliance framework that is set to default has a **default** label.

### Set and remove as default

Prerequisites:

- Owner of the group.

#### From compliance center

To set as default (or remove the default) from [compliance projects report](../../user/compliance/compliance_center/compliance_projects_report.md#compliance-projects-report):

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Hover over a compliance framework, select the **Edit Framework** tab.
1. Select **Set as default**.
1. Select **Save changes**.

To set as default (or remove the default) from [compliance framework report](../../user/compliance/compliance_center/compliance_frameworks_report.md#compliance-frameworks-report):

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.
1. Hover over a compliance framework, select the **Edit Framework** tab.
1. Select **Set as default**.
1. Select **Save changes**.

#### Example GraphQL mutations for setting a default compliance framework

Creating a new compliance framework and setting it as the default framework for the group.

```graphql
mutation {
    createComplianceFramework(
        input: {params: {name: "SOX", description: "Sarbanes-Oxley Act", color: "#87CEEB", default: true}, namespacePath: "gitlab-org"}
    ) {
        framework {
            id
            name
            default
            description
            color
            pipelineConfigurationFullPath
        }
        errors
    }
}
```

Setting an existing compliance framework as the default framework the group.

```graphql
mutation {
    updateComplianceFramework(
        input: {id: "gid://gitlab/ComplianceManagement::Framework/<id>", params: {default: true}}
    ) {
        complianceFramework {
            id
            name
            default
            description
            color
            pipelineConfigurationFullPath
        }
    }
}
```

## Remove a compliance framework from a project

Prerequisites:

- The group to which the project belongs must have a compliance framework.

### From compliance projects report

To remove a compliance framework from one or multiple project in a group, remove the compliance framework through the
[Compliance projects report](../../user/compliance/compliance_center/compliance_projects_report.md#remove-a-compliance-framework-from-projects-in-a-group).
