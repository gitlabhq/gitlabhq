---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Read-only namespaces and projects
---

## Read-only namespaces

{{< details >}}

- Tier: Free
- Offering: GitLab.com

{{< /details >}}

A namespace is placed in a read-only state when it exceeds the [free user limit](free_user_limit.md), and when the namespace visibility is private.

To remove the read-only state of a namespace and its projects, you can:

- [Reduce the number of members](free_user_limit.md#manage-members-in-your-group-namespace) in your namespace.
- [Start a free trial](https://gitlab.com/-/trial_registrations/new), which includes an unlimited number of members.
- [Purchase a paid tier](https://about.gitlab.com/pricing/).

### Restricted actions

When a namespace is in a read-only state, you cannot execute the actions listed in the following table.
If you try to execute a restricted action, you might get a `404` error.

| Feature | Action restricted |
|---------|-------------------|
| Container registry | Create, edit, and delete cleanup policies. <br> Push an image to the container registry. |
| Merge requests | Create and update a merge request. |
| Package registry | Publish a package. |
| CI/CD | Create, edit, administer, and run pipelines. <br>  Create, edit, administer, and run builds. <br>  Create and edit admin environments. <br> Create and edit admin deployments. <br>  Create and edit admin clusters. <br> Create and edit admin releases. |
| Namespaces | **For exceeded free user limits:** Invite new users. |

## Read-only projects

{{< details >}}

- Tier: Free, Premium, Ultimate

{{< /details >}}

A project is placed in a read-only state when it exceeds the allocated storage limit on the:

- Free tier, when any project in the namespace is over the [free limit](storage_usage_quotas.md#free-limit).
- Premium and Ultimate tiers, when any project in the namespace is over the [fixed project limit](storage_usage_quotas.md#fixed-project-limit).

### Restricted actions

When a project is read-only due to storage limits, you can't push or add large files (LFS) to the project's repository.
A banner at the top of the project or namespace page indicates the read-only status.
