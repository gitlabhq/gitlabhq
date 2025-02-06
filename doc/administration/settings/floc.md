---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Federated Learning of Cohorts (FLoC)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Federated Learning of Cohorts (FLoC) was a proposed feature
for Google Chrome that categorized users into different cohorts for interest-based
advertising. FLoC has been replaced by the [Topics API](https://patcg-individual-drafts.github.io/topics/),
which provides similar functionality to help advertisers target and track users.

By default, GitLab opts out of user tracking for interest-based advertising
by sending the following header:

```plaintext
Permissions-Policy: interest-cohort=()
```

This header prevents users from being tracked and categorized in any GitLab instance.
The header is compatible with the Topics API and the deprecated FLoC system.

To enable user tracking for interest-based advertising:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Federated Learning of Cohorts (FLoC)**.
1. Select the **Participate in FLoC** checkbox.
1. Select **Save changes**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
