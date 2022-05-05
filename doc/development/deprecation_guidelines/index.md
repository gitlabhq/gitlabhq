---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Deprecation guidelines

This page includes information about how and when to remove or make [breaking
changes](../contributing/index.md#breaking-changes) to GitLab features.

## Terminology

It's important to understand the difference between **deprecation** and
**removal**:

**Deprecation** is the process of flagging/marking/announcing that a feature is no longer fully supported and may be removed in a future version of GitLab.

**Removal** is the process of actually removing a feature that was previously
deprecated.

## When can a feature be deprecated?

Deprecations should be announced on the [Deprecated feature removal schedule](../../update/deprecations.md).

For steps to create a deprecation entry, see [Deprecations](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations).

## When can a feature be removed/changed?

Generally, feature or configuration can be removed/changed only on major release.
It also should be [deprecated in advance](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations).

For API removals, see the [GraphQL](../../api/graphql/index.md#deprecation-and-removal-process) and [GitLab API](../../api/index.md#compatibility-guidelines) guidelines.

For configuration removals, see the [Omnibus deprecation policy](../../administration/package_information/deprecation_policy.md).

For versioning and upgrade details, see our [Release and Maintenance policy](../../policy/maintenance.md).

## Update the deprecations and removals documentation

The [deprecations](../../update/deprecations.md) and [removals](../../update/removals.md)
documentation is generated from the YAML files located in
[`gitlab/data/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data).

To update the deprecations and removals pages when an entry is added,
edited, or removed:

1. From the command line, navigate to your local clone of the [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) project.
1. Create, edit, or remove the YAML file under [deprecations](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data/deprecations)
   or [removals](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data/removals).
1. Compile the deprecation or removals documentation with the appropriate command:

   - For deprecations:

     ```shell
     bin/rake gitlab:docs:compile_deprecations
     ```

   - For removals:

     ```shell
     bin/rake gitlab:docs:compile_removals
     ```

1. If needed, you can verify the docs are up to date with:

   - For deprecations:

     ```shell
     bin/rake gitlab:docs:check_deprecations
     ```

   - For removals:

     ```shell
     bin/rake gitlab:docs:check_removals
     ```

1. Commit the updated documentation and push the changes.
1. Create a merge request using the [Deprecations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Deprecations.md)
   or [Removals](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Removals.md) templates.

Related Handbook pages:

- <https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes>
- <https://about.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-and-removals-docs>
