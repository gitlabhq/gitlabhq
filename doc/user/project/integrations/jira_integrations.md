---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Jira integrations

## Introduction

GitLab Issues are a tool for discussing ideas and planning and tracking work. However, your organization may already use Jira for these purposes, with
extensive, established data and business processes they rely on.

Although you can [migrate](../../../user/project/import/jira.md) your Jira issues and work exclusively in GitLab, you also have the option of continuing to use Jira by using GitLab's Jira integrations.

## Integrations

The following Jira integrations allow different types of cross-referencing between GitLab activity and Jira issues, with additional features:

- [**Jira integration**](jira.md) - This is built in to GitLab. In a given GitLab project, it can be configured to connect to any Jira instance, self-managed or Cloud.
- [**Jira development panel integration**](../../../integration/jira_development_panel.md) - This connects all GitLab projects under a specified group or personal namespace.
  - If you're using Jira Cloud and GitLab.com, install the [GitLab for Jira](https://marketplace.atlassian.com/apps/1221011/gitlab-for-jira) app in the Atlassian Marketplace and see its [documentation](../../../integration/jira_development_panel.md#gitlab-for-jira-app).
  - For all other environments, use the [Jira DVCS Connector configuration instructions](../../../integration/jira_development_panel.md#configuration).

### Feature comparison

| Capability                                                                  | Jira integration                                                                                                                                              | Jira Development Panel integration                                                                                     |
|-----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| Mention of Jira issue ID in GitLab is automatically linked to that issue    | Yes                                                                                                                                                           | No                                                                                                                     |
| Mention of Jira issue ID in GitLab issue/MR is reflected in the Jira issue  | Yes, as a Jira comment with the GitLab issue/MR title and a link back to it. Its first mention also adds the GitLab page to the Jira issue under “Web links”. | Yes, in the issue’s Development panel                                                                                  |
| Mention of Jira issue ID in GitLab commit message is reflected in the issue | Yes. The entire commit message is added to the Jira issue as a comment and under “Web links”, each with a link back to the commit in GitLab.                  | Yes, in the issue’s Development panel and optionally with a custom comment on the Jira issue using Jira Smart Commits. |
| Mention of Jira issue ID in GitLab branch names is reflected in Jira issue  | No                                                                                                                                                            | Yes, in the issue’s Development panel                                                                                  |
| Record Jira time tracking info against an issue                             | No                                                                                                                                                            | Yes. Time can be specified via Jira Smart Commits.                                                                     |
| Transition or close a Jira issue with a Git commit or merge request         | Yes. Only a single transition type, typically configured to close the issue by setting it to Done.                                                            | Yes. Transition to any state using Jira Smart Commits.                                                                 |
| Display a list of Jira issues                                               | Yes **(PREMIUM)**                                                                                                                                             | No                                                                                                                     |
