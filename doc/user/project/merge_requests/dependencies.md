---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Set a merge request dependency to control the merge order of merge requests with related or dependent content."
title: Merge request dependencies
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Support for complex merge dependencies [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11393) in GitLab 16.6 [with a flag](../../../administration/feature_flags.md) named `remove_mr_blocking_constraints`. Disabled by default.
> - Support for complex merge dependencies [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136775) in GitLab 16.7. Feature flag `remove_mr_blocking_constraints` removed.

A single feature can span several merge requests, spread out across multiple projects,
and the order in which the work merges can be significant. Use merge request dependencies
when it's important to merge work in a specific order. Some examples:

- Ensure changes to a required library merge before changes to a project that
  imports the library.
- Prevent a documentation-only merge request from merging before the feature work
  is itself merged.
- Require a merge request updating a permissions matrix to merge, before merging work
  from someone who doesn't yet have the correct permissions.

If your project `me/myexample` imports a library from `myfriend/library`,
you should update your project when `myfriend/library` releases a new feature.
If you merge your changes to `me/myexample` before `myfriend/library` adds the
new feature, you would break the default branch in your project. A merge request
dependency prevents your work from merging too soon:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%

graph TB
  accTitle: Merge request dependencies
  accDescr: Shows how a merge request dependency prevents work from merging too soon.
  A['me/myexample' project]
  B['myfriend/library' project]
  C[Merge request #1:<br>Create new version 2.5]
  D[Merge request #2:<br>Add version 2.5<br>to build]
  A-->|contains| D
  B---->|contains| C
  D-.->|depends on| C
  C-.->|blocks| D
```

It's possible to mark your `me/myexample` merge request as a [draft](drafts.md)
and explain why in the comments. This approach is manual and does not scale, especially
if your merge request relies on several others in different projects. Instead, you should:

- Track the readiness of an individual merge request with **Draft** or **Ready** status.
- Enforce the order merge requests merge with a merge request dependency.

Merge request dependencies are a **PREMIUM** feature, but GitLab enforces this restriction
only for the *dependent* merge request:

- A **PREMIUM** project's merge request can depend on any other merge request, even in a **FREE** project.
- A **FREE** project's merge request cannot depend on other merge requests.

## Nested dependencies

GitLab versions 16.7 and later support indirect, nested dependencies. A merge request can have up to 10 blockers,
and in turn it can block up to 10 other merge requests. In this example, `myfriend/library!10`
depends on `herfriend/another-lib!1`, which in turn depends on `mycorp/example!100`:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%

graph LR;
    accTitle: Merge request dependency chain
    accDescr: Flowchart that shows how merge request A depends on merge request B, while merge request B depends on merge request C
    A[myfriend/library!10]-->|depends on| B[herfriend/another-lib!1]
    B-->|depends on| C[mycorp/example!100]
```

Nested dependencies do not display in the GitLab UI, but UI support is
proposed in [epic 5308](https://gitlab.com/groups/gitlab-org/-/epics/5308).

NOTE:
A merge request cannot depend on itself (self-referential), but it's possible to create circular dependencies.

## View dependencies for a merge request

If a merge request is dependent on another, the merge request reports section shows
information about the dependency:

![Dependencies in merge request widget](img/dependencies_view_v15_3.png)

To view dependency information on a merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and identify your merge request.
1. Scroll to the merge request reports area. Dependent merge requests display information
   about the total number of dependencies set, such as
   **(status-warning)** **Depends on 1 merge request being merged**.
1. Select **Expand** to view the title, milestone, assignee, and pipeline status
   of each dependency.

Until your merge request's dependencies all merge, your merge request cannot merge. The message
**Merge blocked: you can only merge after the above items are resolved** displays.

### Closed merge requests

Closed merge requests still prevent their dependents from merging, because a merge request can close
without merging its planned work. If a merge request closes and the dependency is no longer relevant,
remove it as a dependency to unblock the dependent merge request.

## Create a new dependent merge request

When you create a new merge request, you can prevent it from merging until after
other specific work merges. This dependency works even if the merge request is in a different project.

Prerequisites:

- You must have at least the Developer role, or have permission to create merge requests in the project.
- The dependent merge request must be in a project in the Premium or Ultimate tier.

To create a new merge request and mark it as dependent on another:

1. [Create a new merge request](creating_merge_requests.md).
1. In **Merge request dependencies**, paste either the reference or the full URL
   to the merge requests that should merge before this work merges. References
   are in the form of `path/to/project!merge_request_id`.
1. Select **Create merge request**.

## Edit a merge request to add a dependency

You can edit an existing merge request and mark it as dependent on another.

Prerequisites:

- You must have at least the Developer role or have permission to edit merge requests in the project.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and identify your merge request.
1. Select **Edit**.
1. In **Merge request dependencies**, paste either the reference or the full URL
   to the merge requests that should merge before this work merges. References
   are in the form of `path/to/project!merge_request_id`.

## Remove a dependency from a merge request

You can edit a dependent merge request and remove a dependency.

Prerequisites:

- You must have a role for the project that allows you to edit merge requests.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and identify your merge request.
1. Select **Edit**.
1. Scroll to **Merge request dependencies** and select **Remove** next to the reference
   for each dependency you want to remove.

   NOTE:
   Merge request dependencies you do not have permission to view are shown as
   **1 inaccessible merge request**. You can still remove the dependency.
1. Select **Save changes**.

## Troubleshooting

### Preserve dependencies on project import or export

Dependencies are not preserved when you import or export a project. For more
information, see [issue #12549](https://gitlab.com/gitlab-org/gitlab/-/issues/12549).
