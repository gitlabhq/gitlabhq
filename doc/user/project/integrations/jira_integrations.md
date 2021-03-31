---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Jira integrations **(FREE)**

If your organization uses [Jira](https://www.atlassian.com/software/jira) issues,
you can [migrate](../../../user/project/import/jira.md) your issues from Jira and work
exclusively in GitLab.

However, if you'd like to continue to use Jira, you can integrate it with GitLab.

There are two ways to use GitLab with Jira:

- [Jira integration](jira.md). Connect a GitLab project
  to a Jira instance. The Jira instance can be hosted by you or in [Atlassian cloud](https://www.atlassian.com/cloud).
- [Jira Development panel integration](../../../integration/jira_development_panel.md).
  Connect all GitLab projects under a group or personal namespace.

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
