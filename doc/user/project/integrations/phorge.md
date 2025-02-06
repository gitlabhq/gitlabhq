---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Phorge
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145863) in GitLab 16.11.

You can use [Phorge](https://we.phorge.it/) as an external issue tracker in GitLab.

## Configure the integration

To configure Phorge in a GitLab project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Phorge**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In **Project URL**, enter the URL to the Phorge project.
1. In **Issue URL**, enter the URL to the Phorge project issue.
   The URL must contain `:id`. GitLab replaces this token with the Maniphest task ID (for example, `T123`).
1. In **New issue URL**, enter the URL to a new Phorge project issue.
   To prefill tags related to this project, you can use `?tags=`.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

In that GitLab project, you can see a link to your Phorge project.
You can now reference your Phorge issues and tasks in GitLab with
`T<ID>`, where `<ID>` is a Maniphest task ID (for example, `T123`).
