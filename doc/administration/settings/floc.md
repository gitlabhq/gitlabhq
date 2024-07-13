---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Federated Learning of Cohorts (FLoC)

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Federated Learning of Cohorts (FLoC) is a new feature of the Chrome browser.
It works by categorizing users into different cohorts, so that
advertisers can use this data to uniquely target and track users. For more
information, see the [FLoC repository](https://github.com/WICG/floc).

To avoid users being tracked and categorized in any GitLab instance, FLoC is
disabled by default by sending the following header:

```plaintext
Permissions-Policy: interest-cohort=()
```

To enable it:

1. On the left sidebar, at the bottom, select **Admin area**.
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
