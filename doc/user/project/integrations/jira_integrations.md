---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Jira integrations **(FREE)**

GitLab can be integrated with [Jira](https://www.atlassian.com/software/jira).

[Issues](../issues/index.md) are a tool for discussing ideas, and planning and tracking work.
However, your organization may already use Jira for these purposes, with extensive, established data
and business processes they rely on.

Although you can [migrate](../../../user/project/import/jira.md) your Jira issues and work
exclusively in GitLab, you can also continue to use Jira by using the GitLab Jira integrations.

## Integration types

There are two different Jira integrations that allow different types of cross-referencing between
GitLab activity and Jira issues, with additional features:

- [Jira integration](jira.md), built in to GitLab. In a given GitLab project, it can be configured
  to connect to any Jira instance, either hosted by you or hosted in
  [Atlassian cloud](https://www.atlassian.com/cloud).
- [Jira development panel integration](../../../integration/jira/index.md). Connects all
  GitLab projects under a specified group or personal namespace.

Jira development panel integration configuration depends on whether:

- You're using GitLab.com or a self-managed GitLab instance.
- You're using Jira on [Atlassian cloud](https://www.atlassian.com/cloud) or on your own server.

The integration you choose depends on the capabilities you require.
You can also install both at the same time.

| Capability | Jira integration | Jira Development panel integration |
|-|-|-|
| Mention a Jira issue ID in GitLab and a link to the Jira issue is created. | Yes. | No. |
| Mention a Jira issue ID in GitLab and the Jira issue shows the GitLab issue or merge request. | Yes. A Jira comment with the GitLab issue or MR title links to GitLab. The first mention is also added to the Jira issue under **Web links**. | Yes, in the issue's Development panel. |
| Mention a Jira issue ID in a GitLab commit message and the Jira issue shows the commit message. | Yes. The entire commit message is displayed in the Jira issue as a comment and under **Web links**. Each message links back to the commit in GitLab. | Yes, in the issue's Development panel and optionally with a custom comment on the Jira issue using Jira Smart Commits. |
| Mention a Jira issue ID in a GitLab branch name and the Jira issue shows the branch name. | No. | Yes, in the issue's Development panel. |
| Add Jira time tracking to an issue. | No. | Yes. Time can be specified using Jira Smart Commits. |
| Use a Git commit or merge request to transition or close a Jira issue. | Yes. Only a single transition type, typically configured to close the issue by setting it to Done. | Yes. Transition to any state using Jira Smart Commits. |
| Display a list of Jira issues. | Yes. **(PREMIUM)** | No. |
| Create a Jira issue from a vulnerability or finding. **(ULTIMATE)** | Yes. | No. |
