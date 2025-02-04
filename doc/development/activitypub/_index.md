---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: ActivityPub
---

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023) in GitLab 16.5 [with two flags](../../administration/feature_flags.md) named `activity_pub` and `activity_pub_project`. Disabled by default. This feature is an [experiment](../../policy/development_stages_support.md).

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available,
an administrator can [enable the feature flags](../../administration/feature_flags.md)
named `activity_pub` and `activity_pub_project`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

Usage of ActivityPub in GitLab is governed by the
[GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

The goal of those documents is to provide an implementation path for adding
Fediverse capabilities to GitLab.

This page describes the conceptual and high level point of view, while
sub-pages discuss implementation in more technical depth (as in, how to
implement this in the actual rails codebase of GitLab).

This feature requires two feature flags:

- `activity_pub`: Enables or disables all ActivityPub-related features.
- `activity_pub_project`: Enables and disable ActivityPub features specific to
  projects. Requires the `activity_pub` flag to also be enabled.

Most of the implementation is being discussed in
[an architecture design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/activity_pub/),
see this document for more information.

For now, see [how to implement an ActivityPub actor](actors/_index.md).
