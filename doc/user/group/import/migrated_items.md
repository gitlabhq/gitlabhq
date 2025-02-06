---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Items migrated when using direct transfer
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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

<!-- vale gitlab_base.OutdatedVersions = NO -->

| Group item           | Introduced in                                                               |
|:---------------------|:----------------------------------------------------------------------------|
| Badges               | [GitLab 13.11](https://gitlab.com/gitlab-org/gitlab/-/issues/292431)        |
| Boards               | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18938)  |
| Board lists          | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24863)  |
| Epics <sup>1</sup>   | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/issues/250281)         |
| Group labels <sup>2</sup> | [GitLab 13.9](https://gitlab.com/gitlab-org/gitlab/-/issues/292429)    |
| Iterations           | [GitLab 13.10](https://gitlab.com/gitlab-org/gitlab/-/issues/292428)        |
| Iteration cadences   | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96570)  |
| Members <sup>3</sup> | [GitLab 13.9](https://gitlab.com/gitlab-org/gitlab/-/issues/299415) |
| Group milestones     | [GitLab 13.10](https://gitlab.com/gitlab-org/gitlab/-/issues/292427)        |
| Namespace settings   | [GitLab 14.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85128) |
| Release milestones   | [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/339422)         |
| Subgroups            | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18938)  |
| Uploads              | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18938)  |

**Footnotes:**

1. State and state ID [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28203) in GitLab 13.7.
   Label associations [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62074) in GitLab 13.12.
   System note metadata [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63551) in GitLab 14.0.
   Epic resource state events [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4.
1. Group labels cannot retain any associated label priorities during import.
   You must prioritize these labels again manually after you migrate the relevant project to the destination instance.
1. See [user contribution and membership mapping](direct_transfer_migrations.md#user-contribution-and-membership-mapping).

<!-- vale gitlab_base.OutdatedVersions = YES -->

### Excluded items

Some group items are excluded from migration because they:

- Might contain sensitive information:
  - CI/CD variables
  - Deploy tokens
  - Webhooks
- Are not supported:
  - Push rules
  - Iteration cadence settings

## Migrated project items

DETAILS:
**Status:** Beta

> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.
> - `bulk_import_projects` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.10.
> - Project-only migrations using API [added](https://gitlab.com/gitlab-org/gitlab/-/issues/390515) in GitLab 15.11.

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

<!-- vale gitlab_base.OutdatedVersions = NO -->

| Project item                            | Introduced in                                                              |
|:----------------------------------------|:---------------------------------------------------------------------------|
| Projects                                | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267945)        |
| Auto DevOps                             | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339410)        |
| Badges                                  | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75029) |
| Branches (including protected branches) <sup>1</sup> | [GitLab 14.7](https://gitlab.com/gitlab-org/gitlab/-/issues/339414) |
| CI Pipelines                            | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339407)        |
| Commit comments                         | [GitLab 15.10](https://gitlab.com/gitlab-org/gitlab/-/issues/391601)       |
| Designs                                 | [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/339421)        |
| Issues                                  | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267946)        |
| Issue boards                            | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71661) |
| Labels                                  | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/339419)        |
| LFS Objects                             | [GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/339405)        |
| Members <sup>2</sup>                    | [GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/341886)        |
| Merge requests                          | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339403)        |
| Push rules                              | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339403)        |
| Milestones                              | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339417)        |
| External pull requests                  | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339409)        |
| Pipeline history                        | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339412)        |
| Pipeline schedules                      | [GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/339408)        |
| Project features                        | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74722) |
| Releases                                | [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/339422)        |
| Release evidences                       | [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/360567)        |
| Repositories                            | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267945)        |
| Snippets                                | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/343438)        |
| Settings                                | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339416)        |
| Uploads                                 | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339401)        |
| Vulnerability reports <sup>3</sup>      | [GitLab 17.7](https://gitlab.com/gitlab-org/gitlab/-/issues/501466)        |
| Wikis                                   | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/345923)        |

<!-- vale gitlab_base.OutdatedVersions = YES -->

**Footnotes:**

1. Imported branches respect the [default branch protection settings](../../project/repository/branches/protected.md) of the destination group.
   These settings might cause an unprotected branch to be imported as protected.
1. See [user contribution and membership mapping](direct_transfer_migrations.md#user-contribution-and-membership-mapping).
1. Vulnerability reports are migrated without their status.
   For more information, see [issue 512859](https://gitlab.com/gitlab-org/gitlab/-/issues/512859).
   For the `ActiveRecord::RecordNotUnique` error when migrating vulnerability reports,
   see [issue 509904](https://gitlab.com/gitlab-org/gitlab/-/issues/509904).

### Issue-related items

Issue-related project items that are migrated to the destination GitLab instance include:

<!-- vale gitlab_base.OutdatedVersions = NO -->

| Issue-related project item      | Introduced in                                                              |
|:--------------------------------|:---------------------------------------------------------------------------|
| Issue iterations                | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96184) |
| Issue resource state events     | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Issue resource milestone events | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Issue resource iteration events | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Merge request URL references    | [GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/issues/267947)        |
| Time tracking                   | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267946)        |

<!-- vale gitlab_base.OutdatedVersions = YES -->

### Merge request-related items

Merge request-related project items that are migrated to the destination GitLab instance include:

<!-- vale gitlab_base.OutdatedVersions = NO -->

| Merge request-related project item      | Introduced in |
|:----------------------------------------|:--------------|
| Multiple merge request assignees        | [GitLab 15.3](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) |
| Merge request reviewers                 | [GitLab 15.3](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) |
| Merge request approvers                 | [GitLab 15.3](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) |
| Merge request resource state events     | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) |
| Merge request resource milestone events | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) |
| Issue URL references                    | [GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/issues/267947) |
| Time tracking                           | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339403) |

<!-- vale gitlab_base.OutdatedVersions = YES -->

### Setting-related items

Setting-related project items that are migrated to the destination GitLab instance include:

<!-- vale gitlab_base.OutdatedVersions = NO -->

| Setting-related project item | Introduced in                                                              |
|:-----------------------------|:---------------------------------------------------------------------------|
| Avatar                       | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75249) |
| Container expiration policy  | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75653) |
| Project properties           | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75898) |
| Service Desk                 | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75653) |

<!-- vale gitlab_base.OutdatedVersions = YES -->

### Excluded items

Some project items are excluded from migration because they:

- Might contain sensitive information:
  - CI/CD variables
  - CI/CD job logs
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
  - Merge request approval rules

    NOTE:
    Approval rules related to project settings are imported.

  - Container registry
  - Environments
  - Feature flags
  - Infrastructure registry
  - Package registry
  - Pages domains
  - Remote mirrors
