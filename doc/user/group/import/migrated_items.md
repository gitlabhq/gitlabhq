---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Items migrated when using direct transfer
description: "Project and group items included or excluded when using direct transfer."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Many items are migrated when using the direct transfer method, and some are excluded.

## Migrated group items

The group items that are migrated depend on the version of GitLab you use on the destination. To determine if a
specific group item is migrated:

1. Check the [`groups/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/bulk_imports/groups/stage.rb)
   file for all editions and the
   [`groups/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/bulk_imports/groups/stage.rb) file
   for Enterprise Edition for your version on the destination. For example, for version 15.9:
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/bulk_imports/groups/stage.rb> (all editions).
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/ee/lib/ee/bulk_imports/groups/stage.rb> (Enterprise
     Edition).
1. Check the
   [`group/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)
   file for groups for your version on the destination. For example, for version 15.9:
   <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/gitlab/import_export/group/import_export.yml>.

Any other group items are **not** migrated.

Group items that are migrated to the destination GitLab instance include:

- Badges
- Boards
- Board lists
- Epics
- Epic boards
- Epic board lists
- Group labels

  {{< alert type="note" >}}

  Group labels cannot retain any associated label priorities during import.
  You must prioritize these labels again manually after you migrate the relevant project to the destination instance.

  {{< /alert >}}

- Group milestones
- Iterations
- Iteration cadences
- [Members](direct_transfer_migrations.md#user-membership-mapping)
- Namespace settings
- Release milestones
- Subgroups
- Uploads
- Wikis

### Excluded items

Some group items are excluded from migration because they:

- Might contain sensitive information:
  - CI/CD variables
  - Deploy tokens
  - Webhooks
- Are not supported:
  - Custom fields
  - Iteration cadence settings
  - Pending member invitations
  - Push rules

## Migrated project items

{{< history >}}

- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.
- `bulk_import_projects` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.10.
- Project migrations through the API [added](https://gitlab.com/gitlab-org/gitlab/-/issues/390515) in GitLab 15.11.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/461326) in GitLab 18.3.

{{< /history >}}

If you choose to migrate projects when you [select groups to migrate](direct_transfer_migrations.md#select-the-groups-and-projects-to-import),
project items are migrated with the projects.

The project items that are migrated depends on the version of GitLab you use on the destination. To determine if a
specific project item is migrated:

1. Check the [`projects/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/bulk_imports/projects/stage.rb)
   file for all editions and the
   [`projects/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/bulk_imports/projects/stage.rb)
   file for Enterprise Edition for your version on the destination. For example, for version 15.9:
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/bulk_imports/projects/stage.rb> (all editions).
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/ee/lib/ee/bulk_imports/projects/stage.rb> (Enterprise
     Edition).
1. Check the
   [`project/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml)
   file for projects for your version on the destination. For example, for version 15.9:
   <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/gitlab/import_export/project/import_export.yml>.

Any other project items are **not** migrated.

If you choose not to migrate projects along with groups or if you want to retry a project migration, you can
initiate project-only migrations using the [API](../../../api/bulk_imports.md).

Project items that are migrated to the destination GitLab instance include:

- Auto DevOps
- Badges
- Branches (including protected branches)

  {{< alert type="note" >}}

  Imported branches respect the [default branch protection settings](../../project/repository/branches/protected.md) of the destination group.
  These settings might cause an unprotected branch to be imported as protected.

  {{< /alert >}}

- CI pipelines
- Commit comments
- Designs
- External merge requests
- Issues
- Issue boards
- Labels
- LFS objects
- [Members](direct_transfer_migrations.md#user-membership-mapping)
- Merge requests
- Milestones
- Pipeline history
- Pipeline schedules
- Projects
- Project features
- Push rules
- Releases
- Release evidences
- Repositories
- Settings
- Snippets
- Uploads
- Vulnerability reports

  {{< alert type="note" >}}

  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/501466) in GitLab 17.7.
  Vulnerability reports are migrated without their status.
  For more information, see [issue 512859](https://gitlab.com/gitlab-org/gitlab/-/issues/512859).
  For the `ActiveRecord::RecordNotUnique` error when migrating vulnerability reports,
  see [issue 509904](https://gitlab.com/gitlab-org/gitlab/-/issues/509904).

  {{< /alert >}}

- Wikis

### Issue-related items

Issue-related project items that are migrated to the destination GitLab instance include:

- Issue comments
- Issue iterations
- Issue resource iteration events
- Issue resource milestone events
- Issue resource state events
- Merge request URL references
- Time tracking

### Merge request-related items

Merge request-related project items that are migrated to the destination GitLab instance include:

- Issue URL references
- Merge request approvers
- Merge request comments
- Merge request resource milestone events
- Merge request resource state events
- Merge request reviewers
- Multiple merge request assignees
- Time tracking

### Setting-related items

Setting-related project items that are migrated to the destination GitLab instance include:

- Avatar
- Container expiration policy
- Project properties
- Service Desk

### Excluded items

Some project items are excluded from migration because they:

- Might contain sensitive information:
  - CI/CD job logs
  - CI/CD variables
  - Container registry images
  - Deploy keys
  - Deploy tokens
  - Encrypted tokens
  - Job artifacts
  - Pipeline schedule variables
  - Pipeline triggers
  - Webhooks
- Are not supported:
  - Agents
  - Container registry
  - Custom fields
  - Environments
  - Feature flags
  - Infrastructure registry
  - Instance administrators in branch protection rules when migrating
    from GitLab Self-Managed to GitLab.com or GitLab Dedicated
  - Linked issues
  - Merge request approval rules
  - Merge request dependencies
  - Package registry
  - Pages domains
  - Pending member invitations
  - Remote mirrors
  - Wiki comments

    {{< alert type="note" >}}

    Approval rules related to project settings are imported.

    {{< /alert >}}

- Do not contain recoverable data:
  - Merge requests with no diff or source information
    (for more information, see [issue 537943](https://gitlab.com/gitlab-org/gitlab/-/issues/537943))
