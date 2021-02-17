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
- [Jira development panel integration](../../../integration/jira_development_panel.md). Connects all
  GitLab projects under a specified group or personal namespace.

Jira development panel integration configuration depends on whether:

- You're using GitLab.com or a self-managed GitLab instance.
- You're using Jira on [Atlassian cloud](https://www.atlassian.com/cloud) or on your own server.

| You use Jira on: | For the Jira development panel integration, GitLab.com customers need:                                                                                                                                                        | For the Jira development panel integration, GitLab self-managed customers need:                                                                                                                                                                                               |
|:-------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Atlassian cloud    | The [GitLab.com for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview) application installed from the [Atlassian Marketplace](https://marketplace.atlassian.com). | The [GitLab.com for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview), using a workaround process. See a [relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/268278) for more information.            |
| Your own server    | The [Jira DVCS connector](../../../integration/jira_development_panel.md).                                                                                                                                                      | The [Jira DVCS connector](../../../integration/jira_development_panel.md).                                                                                                                                                                                                      |

NOTE:
DVCS means distributed version control system.

## Feature comparison

The integration to use depends on the capabilities your require. You can install both at the same
time.

| Capability                                                                  | Jira integration                                                                                                                                              | Jira Development Panel integration                                                                                     |
|:----------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------|
| Mention of Jira issue ID in GitLab is automatically linked to that issue    | Yes                                                                                                                                                           | No                                                                                                                     |
| Mention of Jira issue ID in GitLab issue/MR is reflected in the Jira issue  | Yes, as a Jira comment with the GitLab issue/MR title and a link back to it. Its first mention also adds the GitLab page to the Jira issue under “Web links”. | Yes, in the issue’s Development panel                                                                                  |
| Mention of Jira issue ID in GitLab commit message is reflected in the issue | Yes. The entire commit message is added to the Jira issue as a comment and under “Web links”, each with a link back to the commit in GitLab.                  | Yes, in the issue’s Development panel and optionally with a custom comment on the Jira issue using Jira Smart Commits. |
| Mention of Jira issue ID in GitLab branch names is reflected in Jira issue  | No                                                                                                                                                            | Yes, in the issue’s Development panel                                                                                  |
| Record Jira time tracking information against an issue                      | No                                                                                                                                                            | Yes. Time can be specified via Jira Smart Commits.                                                                     |
| Transition or close a Jira issue with a Git commit or merge request         | Yes. Only a single transition type, typically configured to close the issue by setting it to Done.                                                            | Yes. Transition to any state using Jira Smart Commits.                                                                 |
| Display a list of Jira issues                                               | Yes **(PREMIUM)**                                                                                                                                             | No                                                                                                                     |
| Create a Jira issue from a vulnerability or finding **(ULTIMATE)**          | Yes                                    | No                     |
