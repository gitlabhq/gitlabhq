---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Deprecation guidelines

This page includes information about how and when to remove or make breaking
changes to GitLab features.

## Terminology

It's important to understand the difference between **deprecation** and
**removal**:

**Deprecation** is the process of flagging/marking/announcing that a feature is no longer fully supported and may be removed in a future version of GitLab.

**Removal** is the process of actually removing a feature that was previously
deprecated.

## When can a feature be deprecated?

A feature can be deprecated at any time, provided there is a viable alternative.

Deprecations should be announced via [release posts](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations).

## When can a feature be removed/changed?

Generally, feature or configuration can be removed/changed only on major release.
It also should be [deprecated in advance](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations).

For API removals, see the [GraphQL](../../api/graphql/index.md#deprecation-and-removal-process) and [GitLab API](../../api/index.md#compatibility-guidelines) guidelines.

For configuration removals, see the [Omnibus deprecation policy](https://docs.gitlab.com/omnibus/package-information/deprecation_policy.html).

For versioning and upgrade details, see our [Release and Maintenance policy](../../policy/maintenance.md).
