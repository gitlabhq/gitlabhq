---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Read-only namespaces
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

On GitLab.com, a top-level namespace is placed in a read-only state when it either:

- Exceeds the [free user limit](free_user_limit.md) when the namespace visibility is private.
- Exceeds the [storage usage quota](storage_usage_quotas.md), regardless of namespace visibility.

While a namespace is in a read-only state, a banner appears at the
top of the page.

Your ability to write new data to read-only namespaces is restricted. For more
information, see [Restricted actions](#restricted-actions).

## Remove the read-only state

To restore a namespace to its standard state, you can:

- For exceeded free user limits:
  - [Reduce the number of members](free_user_limit.md#manage-members-in-your-group-namespace) in your namespace.
  - [Start a free trial](https://gitlab.com/-/trial_registrations/new), which includes an unlimited number of members.
  - [Purchase a paid tier](https://about.gitlab.com/pricing/).

## Restricted actions

| Feature | Action restricted |
|---------|-------------------|
| Container registry | Create, edit, and delete cleanup policies <br> Push an image to the container registry |
| Merge Requests | Create and update an MR |
| Package registry | Publish a package |
| Repositories | Add tags <br> Create new branches <br> Create and update commit status <br> Push and force push to non-protected branches <br> Push and force push to protected branches <br> Upload files <br> Create merge requests |
| CI/CD | Create, edit, admin, and run pipelines <br>  Create, edit, admin, and run builds <br>  Create and edit admin environments <br> Create and edit admin deployments <br>  Create and edit admin clusters <br> Create and edit admin releases |
| Namespaces | **For exceeded free user limits:** Invite new users |

When you try to execute a restricted action in a read-only namespace, you might get a `404` error.

## Related topics

- [Free user limit](free_user_limit.md)
