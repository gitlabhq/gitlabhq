---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Federated Learning of Cohorts (FLoC) **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60933) in GitLab Free 13.12.

Federated Learning of Conhorts (FLoC) is a feature that the Chrome browser has
rolled out, where users are categorized into different cohorts, so that
advertisers can use this data to uniquely target and track users. For more
information, visit the [FLoC repository](https://github.com/WICG/floc).

To avoid users being tracked and categorized in any GitLab instance, FLoC is
disabled by default by sending the following header:

```plaintext
Permissions-Policy: interest-cohort=()
```

To enable it:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**.
1. Expand **Federated Learning of Cohorts**.
1. Check the box.
1. Click **Save changes**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
